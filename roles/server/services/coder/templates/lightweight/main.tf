# Light Debian OCI container with no root access, set up from a dotfiles repo. The rest is in common.tf
locals {
  # The smallest image with what the agent (curl) and the git-clone and dotfiles modules (git) need
  image   = "docker:library/buildpack-deps:trixie-scm"
  address = one(incus_instance.workspace[*].ipv4_address)

  # The image has no such user, and nothing in the container could add one. The provider can only
  # push files once the container is running, which is why the entrypoint has to wait for this
  passwd = <<-EOT
    root:x:0:0:root:/root:/bin/bash
    ${local.user}:x:${local.uid}:${local.uid}::${local.home}:${local.shell}
  EOT

  entrypoint = join("; ", [
    "until grep -q ^${local.user}: /etc/passwd && [ -x ${local.shell} ]",
    "do sleep 1",
    "done",
    "echo \"$CODER_INIT_SCRIPT\" | base64 -d > /tmp/coder-init.sh",
    "exec setpriv --no-new-privs sh /tmp/coder-init.sh",
  ])
}

resource "incus_instance" "workspace" {
  count       = data.coder_workspace.me.start_count
  name        = local.name
  description = "Coder: ${local.owner}/${local.workspace}"
  project     = local.project
  type        = "container"
  image       = local.image
  profiles    = []
  target      = incus_storage_volume.home.location

  config = merge(local.config, {
    "oci.uid"        = local.uid
    "oci.gid"        = local.uid
    "oci.entrypoint" = "sh -c '${local.entrypoint}'"

    "environment.USER" = local.user
    "environment.HOME" = local.home
    "environment.PATH" = local.path

    # Read by the entrypoint. The container only exists while running, as does the agent
    "environment.CODER_AGENT_TOKEN" = coder_agent.main[0].token
    "environment.CODER_INIT_SCRIPT" = base64encode(coder_agent.main[0].init_script)
  })

  file {
    content     = local.passwd
    target_path = "/etc/passwd"
    mode        = "0644"
  }

  file {
    content     = local.shell_script
    target_path = local.shell
    mode        = "0755"
  }

  dynamic "device" {
    for_each = concat([
      {
        name       = "root"
        type       = "disk"
        properties = { path = "/", pool = local.pool, size = "4GiB" }
      },

      # The dotfiles' home-manager needs /nix, which the user can't create here and would be lost on every
      # start anyway. So it's a view of ~/.nix, created on first use and owned by the user so that a
      # single-user Nix install can write to it
      {
        name = "nix"
        type = "disk"
        properties = {
          path           = "/nix"
          pool           = local.pool
          source         = "${incus_storage_volume.home.name}/.nix"
          "initial.uid"  = local.uid
          "initial.gid"  = local.uid
          "initial.mode" = "0755"
        }
      },
    ], local.devices)

    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }
}
