# Debian container with no root access, set up from a dotfiles repo. See docs/coder-workspaces.md
#
# Coder runs this for each workspace and keeps its state, using a certificate limited to the coder
# project. Containers are replaced on every start. Only the volumes are kept, until the workspace is deleted
terraform {
  required_providers {
    coder = {
      source  = "coder/coder"
      version = "2.19.0"
    }
    incus = {
      source  = "lxc/incus"
      version = "1.0.2"
    }
  }
}

locals {
  project = "coder"
  pool    = "coder-ws-pool-01"
  image   = "docker:library/buildpack-deps:trixie-scm"

  nodes = sort([for name, member in data.incus_cluster.this.members : name if member.status == "Online"])
  node  = element(local.nodes, parseint(substr(data.coder_workspace.me.id, 0, 7), 16))

  parent = "vlan98"

  owner = lower(data.coder_workspace_owner.me.name)
  user  = local.owner
  uid   = 1000
  home  = "/home/${local.user}"

  # Incus limits names to 63 characters. The volumes stay on the id, as a workspace can be renamed
  workspace = lower(data.coder_workspace.me.name)
  full_name = "coder-${local.owner}-${local.workspace}"
  name      = length(local.full_name) <= 63 ? local.full_name : "${substr(local.full_name, 0, 54)}-${substr(data.coder_workspace.me.id, 0, 8)}"

  size = {
    small  = { cpu = "2", memory = "4GiB" }
    medium = { cpu = "4", memory = "8GiB" }
    large  = { cpu = "6", memory = "12GiB" }
  }[data.coder_parameter.size.value]

  # The image has no such user, and nothing in the container could add one. The provider can only
  # push files once the container is running, which is why the entrypoint has to wait for this
  passwd = <<-EOT
    root:x:0:0:root:/root:/bin/bash
    ${local.user}:x:${local.uid}:${local.uid}::${local.home}:${local.shell}
  EOT

  # Dotfiles pick the login shell by linking it here. Without that, or a dotfiles repo at all, it stays
  # as bash, as a missing login shell would stop terminals from opening
  shell        = "/usr/local/bin/workspace-shell"
  shell_script = <<-EOT
    #!/bin/sh
    if [ -x "$HOME/.login-shell" ]; then
      exec "$HOME/.login-shell" "$@"
    fi
    exec /bin/bash "$@"
  EOT

  entrypoint = join("; ", [
    "until grep -q ^${local.user}: /etc/passwd && [ -x ${local.shell} ]",
    "do sleep 1",
    "done",
    "echo \"$CODER_INIT_SCRIPT\" | base64 -d > /tmp/coder-init.sh",
    "exec setpriv --no-new-privs sh /tmp/coder-init.sh",
  ])
}

provider "coder" {}

provider "incus" {
  config_dir                = "/var/lib/coder/incus"
  accept_remote_certificate = true
  default_remote            = "cluster"

  remote {
    name    = "cluster"
    address = "https://10.10.0.254:8443"
  }

  remote {
    name     = "docker"
    address  = "https://docker.io"
    protocol = "oci"
    public   = true
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "incus_cluster" "this" {}

data "coder_parameter" "size" {
  name         = "size"
  display_name = "Size"
  description  = "CPU and memory. This can be changed later, and applies on the next start"
  icon         = "/emojis/1f4cf.png"
  order        = 1
  default      = "small"
  mutable      = true

  option {
    name        = "Small"
    description = "2 CPU, 4GiB"
    value       = "small"
  }
  option {
    name        = "Medium"
    description = "4 CPU, 8GiB"
    value       = "medium"
  }
  option {
    name        = "Large"
    description = "6 CPU, 12GiB"
    value       = "large"
  }
}

data "coder_parameter" "repo" {
  name         = "repo"
  display_name = "Repository"
  description  = "Git URL to clone into your home directory on first start. Leave empty for none"
  icon         = "/icon/git.svg"
  order        = 2
  default      = ""
  mutable      = true
}

data "coder_parameter" "use_dotfiles" {
  name         = "use_dotfiles"
  display_name = "Use dotfiles"
  description  = "Run a dotfiles repository on start. Without it you get a plain Debian shell"
  icon         = "/icon/dotfiles.svg"
  order        = 3
  type         = "bool"
  default      = "true"
  mutable      = true
}

resource "coder_agent" "main" {
  os   = "linux"
  arch = "amd64"

  metadata {
    display_name = "CPU"
    key          = "cpu"
    script       = "coder stat cpu"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Memory"
    key          = "memory"
    script       = "coder stat mem"
    interval     = 10
    timeout      = 1
  }

  metadata {
    display_name = "Disk"
    key          = "disk"
    script       = "coder stat disk --path ${local.home}"
    interval     = 60
    timeout      = 1
  }
}

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = coder_agent.main.id

  item {
    key   = "Container"
    value = local.name
  }
  item {
    key   = "Address"
    value = incus_instance.workspace[0].ipv4_address
  }
}

module "git_clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "2.0.5"
  agent_id = coder_agent.main.id
  url      = data.coder_parameter.repo.value
  base_dir = local.home
}

module "dotfiles" {
  count                 = tobool(data.coder_parameter.use_dotfiles.value) ? data.coder_workspace.me.start_count : 0
  source                = "registry.coder.com/coder/dotfiles/coder"
  version               = "1.4.2"
  agent_id              = coder_agent.main.id
  default_dotfiles_uri  = "https://github.com/CertifiKate/nix-dotfiles"
  coder_parameter_order = 4
}

resource "incus_storage_volume" "home" {
  name        = "ws-${data.coder_workspace.me.id}-home"
  description = "Coder: home of ${local.owner}/${local.workspace}"
  pool        = local.pool
  project     = local.project
  target      = local.node

  config = {
    "size"         = "8GiB"
    "initial.uid"  = local.uid
    "initial.gid"  = local.uid
    "initial.mode" = "0755"

    "zfs.use_refquota" = "true"
  }

  lifecycle {
    ignore_changes = all
  }
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

  config = {
    "limits.cpu"           = local.size.cpu
    "limits.memory"        = local.size.memory
    "cluster.evacuate"     = "stop"
    "user.coder.owner"     = local.owner
    "user.coder.workspace" = local.workspace
    "user.coder.template"  = data.coder_workspace.me.template_name
    "oci.uid"              = local.uid
    "oci.gid"              = local.uid
    "oci.entrypoint"       = "sh -c '${local.entrypoint}'"

    "environment.CODER_AGENT_TOKEN" = coder_agent.main.token
    "environment.CODER_INIT_SCRIPT" = base64encode(coder_agent.main.init_script)
    "environment.USER"              = local.user
    "environment.HOME"              = local.home
    "environment.PATH"              = "${local.home}/.local/bin:/usr/local/bin:/usr/bin:/bin"
  }

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

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = local.pool
      size = "2GiB"
    }
  }

  device {
    name = "home"
    type = "disk"
    properties = {
      path   = local.home
      pool   = local.pool
      source = incus_storage_volume.home.name
    }
  }

  # Nix only works from /nix, so that's a view of ~/.nix. It's empty and unused for anything not using Nix
  device {
    name = "nix"
    type = "disk"
    properties = {
      path   = "/nix"
      pool   = local.pool
      source = "${incus_storage_volume.home.name}/.nix"

      # Created on first use, and owned by the user so that a single-user Nix install can write to it
      "initial.uid"  = local.uid
      "initial.gid"  = local.uid
      "initial.mode" = "0755"
    }
  }

  # Private stops workspaces on the same node from reaching each other. The router covers other nodes
  device {
    name = "eth0"
    type = "nic"
    properties = {
      nictype = "macvlan"
      parent  = local.parent
      mode    = "private"
    }
  }
}
