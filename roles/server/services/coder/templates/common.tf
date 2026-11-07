# A template adds its incus_instance "workspace", using local.config and local.devices, and sets
# local.image and local.address
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

  nodes = sort([for name, member in data.incus_cluster.this.members : name if member.status == "Online"])
  node  = element(local.nodes, parseint(substr(data.coder_workspace.me.id, 0, 7), 16))

  parent = "vlan98"

  owner = lower(data.coder_workspace_owner.me.name)
  user  = local.owner
  uid   = 1000
  home  = "/home/${local.user}"
  path  = "${local.home}/.local/bin:/usr/local/bin:/usr/bin:/bin"

  # Incus limits names to 63 characters. The volumes stay on the id, as a workspace can be renamed
  workspace = lower(data.coder_workspace.me.name)
  full_name = "coder-${local.owner}-${local.workspace}"
  name      = length(local.full_name) <= 63 ? local.full_name : "${substr(local.full_name, 0, 54)}-${substr(data.coder_workspace.me.id, 0, 8)}"

  size = {
    small  = { cpu = "2", memory = "4GiB" }
    medium = { cpu = "4", memory = "8GiB" }
    large  = { cpu = "6", memory = "12GiB" }
  }[data.coder_parameter.size.value]

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

  # Merged into each template's instance config. Each template passes the agent's token its own way
  config = {
    "limits.cpu"           = local.size.cpu
    "limits.memory"        = local.size.memory
    "cluster.evacuate"     = "stop"
    "user.coder.owner"     = local.owner
    "user.coder.workspace" = local.workspace
    "user.coder.template"  = data.coder_workspace.me.template_name
  }

  # Every device but the root disk, whose size is up to the template
  devices = [
    {
      name = "home"
      type = "disk"
      properties = {
        path   = local.home
        pool   = local.pool
        source = incus_storage_volume.home.name
      }
    },

    # Private stops workspaces on the same node from reaching each other. The router covers other nodes
    {
      name = "eth0"
      type = "nic"
      properties = {
        nictype = "macvlan"
        parent  = local.parent
        mode    = "private"
      }
    },
  ]
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

  remote {
    name     = "images"
    address  = "https://images.linuxcontainers.org"
    protocol = "simplestreams"
    public   = true
  }
}

data "coder_workspace" "me" {}
data "coder_workspace_owner" "me" {}
data "incus_cluster" "this" {}

data "coder_external_auth" "github" {
  id       = "github"
  optional = true
}

# For gh and anything else that reads it. Empty until GitHub is linked, and picked up on the next start
resource "coder_env" "gh_token" {
  count    = data.coder_workspace.me.start_count
  agent_id = coder_agent.main[0].id
  name     = "GH_TOKEN"
  value    = data.coder_external_auth.github.access_token
}

data "coder_parameter" "size" {
  name         = "size"
  display_name = "Size"
  description  = "CPU and memory. Can be changed later, and applies on the next restart"
  icon         = "/emojis/1f4cf.png"
  order        = 1
  default      = "small"
  mutable      = true
  form_type    = "radio"

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
  description  = "Git URL to clone into your home directory, which VS Code then opens. Optional"
  icon         = "/icon/git.svg"
  order        = 2
  default      = ""
  mutable      = true

  validation {
    regex = "^$|^(https://|ssh://|git@)\\S+$"
    error = "Use an https://, ssh:// or git@ URL"
  }
}

data "coder_parameter" "use_dotfiles" {
  name         = "use_dotfiles"
  display_name = "Use dotfiles"
  description  = "Run a dotfiles repository on every start. Without it you get a plain Debian shell"
  icon         = "/icon/dotfiles.svg"
  order        = 3
  type         = "bool"
  default      = "true"
  mutable      = true
  form_type    = "switch"
}

resource "coder_agent" "main" {
  count = data.coder_workspace.me.start_count
  os    = "linux"
  arch  = "amd64"

  # VS Code is the module below, as the built-in button can't open the repo
  display_apps {
    vscode          = false
    vscode_insiders = false
    web_terminal    = true
    ssh_helper      = true

    port_forwarding_helper = true
  }

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
    display_name = "Home disk"
    key          = "disk"
    script       = "coder stat disk --path ${local.home}"
    interval     = 60
    timeout      = 1
  }

  metadata {
    display_name = "Root disk"
    key          = "root_disk"
    script       = "coder stat disk --path /"
    interval     = 60
    timeout      = 1
  }
}

resource "coder_metadata" "workspace" {
  count       = data.coder_workspace.me.start_count
  resource_id = coder_agent.main[0].id

  item {
    key   = "Container"
    value = local.name
  }
  item {
    key   = "Address"
    value = local.address
  }
}

module "git_clone" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/git-clone/coder"
  version  = "2.0.5"
  agent_id = coder_agent.main[0].id
  url      = data.coder_parameter.repo.value
  base_dir = local.home
}

module "vscode" {
  count    = data.coder_workspace.me.start_count
  source   = "registry.coder.com/coder/vscode-desktop/coder"
  version  = "1.3.0"
  agent_id = coder_agent.main[0].id
  folder   = data.coder_parameter.repo.value != "" ? module.git_clone[0].repo_dir : local.home
}

# VS Code in the browser, for machines without it installed
module "code_server" {
  count     = data.coder_workspace.me.start_count
  source    = "registry.coder.com/coder/code-server/coder"
  version   = "1.6.0"
  agent_id  = coder_agent.main[0].id
  folder    = data.coder_parameter.repo.value != "" ? module.git_clone[0].repo_dir : local.home
  subdomain = false

  # Rather than /tmp, which is wiped (or RAM) each start, so that it isn't downloaded again every time
  install_prefix = "${local.home}/.cache/code-server"
}

module "dotfiles" {
  count                 = tobool(data.coder_parameter.use_dotfiles.value) ? data.coder_workspace.me.start_count : 0
  source                = "registry.coder.com/coder/dotfiles/coder"
  version               = "1.4.2"
  agent_id              = coder_agent.main[0].id
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
