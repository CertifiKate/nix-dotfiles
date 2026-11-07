# Debian system container that can run dev containers, set up from a dotfiles repo
locals {
  image   = "images:debian/13/cloud"
  address = incus_instance.workspace.ipv4_address

  # The agent's script, token and init script are user.* keys in the instance config, which the container
  # reads live through the Incus guest API. So a template change reaches an existing container on its
  # next start, rather than only through cloud-init on the first boot. They're only set while running
  guest_api = "curl -fsS --unix-socket /dev/incus/sock http://incus/1.0/config"

  agent_config = data.coder_workspace.me.start_count == 0 ? {} : {
    "user.coder.agent-script" = local.agent_script
    "user.coder.agent-token"  = coder_agent.main[0].token
    "user.coder.init-script"  = base64encode(coder_agent.main[0].init_script)
  }

  agent_script = <<-EOT
    #!/bin/sh
    set -eu
    token=$(${local.guest_api}/user.coder.agent-token)
    ${local.guest_api}/user.coder.init-script | base64 -d >/run/coder-init.sh
    chmod 0644 /run/coder-init.sh
    cd ${local.home}
    exec runuser -u ${local.user} -- env CODER_AGENT_TOKEN="$token" HOME=${local.home} USER=${local.user} PATH=${local.path} sh /run/coder-init.sh
  EOT


  agent_unit = <<-EOT
    [Unit]
    Description=Coder agent
    Wants=network-online.target
    After=network-online.target docker.service

    [Service]
    ExecStartPre=${local.guest_api}/user.coder.agent-script -o /run/coder-agent
    ExecStart=/bin/sh /run/coder-agent
    Restart=always
    RestartSec=10

    [Install]
    WantedBy=multi-user.target
  EOT

  # Keeps the root disk from filling up. Only touches what nothing is using: images no container (even a
  # stopped one) was made from, build cache, and Nix generations that aren't current, all older than a week
  cleanup_script = <<-EOT
    #!/bin/sh
    docker image prune --all --force --filter until=168h
    docker builder prune --all --force --filter until=168h
    if [ -x ${local.home}/.nix-profile/bin/nix-collect-garbage ]; then
      runuser -u ${local.user} -- env HOME=${local.home} ${local.home}/.nix-profile/bin/nix-collect-garbage --delete-older-than 7d
    fi
    apt-get clean
  EOT

  cleanup_unit = <<-EOT
    [Unit]
    Description=Clean up unused Docker images and Nix generations
    After=docker.service

    [Service]
    Type=oneshot
    ExecStart=/usr/local/sbin/workspace-cleanup
  EOT

  # Persistent, so that a day spent stopped catches up on the next start
  cleanup_timer = <<-EOT
    [Unit]
    Description=Daily workspace cleanup

    [Timer]
    OnCalendar=daily
    Persistent=true
    RandomizedDelaySec=1h

    [Install]
    WantedBy=timers.target
  EOT

  # Only runs on the first boot. Changing it later does nothing to existing workspaces
  user_data = join("\n", ["#cloud-config", yamlencode({
    # Replaces the image's default user, which would otherwise take uid 1000
    users = [{
      name           = local.user
      uid            = local.uid
      homedir        = local.home
      no_create_home = true
      shell          = local.shell
      lock_passwd    = true
      sudo           = "ALL=(ALL) NOPASSWD:ALL"
    }]

    package_update = true
    packages = [
      "ca-certificates", "curl", "git", "openssh-client", "sudo", "xz-utils",
      "docker.io", "docker-buildx", "docker-compose",
      "nodejs", "npm",
    ]

    write_files = [
      { path = local.shell, permissions = "0755", content = local.shell_script },
      { path = "/etc/systemd/system/coder-agent.service", permissions = "0644", content = local.agent_unit },
      { path = "/usr/local/sbin/workspace-cleanup", permissions = "0700", content = local.cleanup_script },
      { path = "/etc/systemd/system/workspace-cleanup.service", permissions = "0644", content = local.cleanup_unit },
      { path = "/etc/systemd/system/workspace-cleanup.timer", permissions = "0644", content = local.cleanup_timer },

      # Container logs otherwise grow without limit. This one rotates, at 100MB a container
      { path = "/etc/docker/daemon.json", permissions = "0644", content = jsonencode({ "log-driver" = "local" }) },
    ]

    runcmd = [
      "usermod -aG docker ${local.user}",
      "npm install -g @devcontainers/cli",
      "npm cache clean --force",
      "apt-get clean",

      "systemctl enable workspace-cleanup.timer",
      "systemctl start --no-block workspace-cleanup.timer",
      "systemctl enable coder-agent.service",
      "systemctl start --no-block coder-agent.service",
    ]
  })])
}

# Coder runs `devcontainer up` on this once the startup scripts are done, and the agent also picks up
# any other devcontainer.json under the home directory, to start from the dashboard
resource "coder_devcontainer" "repo" {
  count            = data.coder_parameter.repo.value != "" ? data.coder_workspace.me.start_count : 0
  agent_id         = coder_agent.main[0].id
  workspace_folder = module.git_clone[0].repo_dir
}

resource "incus_instance" "workspace" {
  name        = local.name
  description = "Coder: ${local.owner}/${local.workspace}"
  project     = local.project
  type        = "container"
  image       = local.image
  profiles    = []
  target      = incus_storage_volume.home.location
  running     = data.coder_workspace.me.start_count == 1

  config = merge(local.config, local.agent_config, {
    # What Docker needs in an unprivileged container. The project has to allow these
    "security.nesting"                     = "true"
    "security.syscalls.intercept.mknod"    = "true"
    "security.syscalls.intercept.setxattr" = "true"

    "cloud-init.user-data" = local.user_data
  })

  # Docker images and build caches live on the root disk, and so does Nix if the dotfiles install it.
  # workspace-cleanup keeps it down
  dynamic "device" {
    for_each = concat([{
      name       = "root"
      type       = "disk"
      properties = { path = "/", pool = local.pool, size = "12GiB" }
    }], local.devices)

    content {
      name       = device.value.name
      type       = device.value.type
      properties = device.value.properties
    }
  }

  # A newer image would otherwise replace the container, and everything installed in it
  lifecycle {
    ignore_changes = [image]
  }
}
