
instances = {
  "monitor-01" = {
    description = "Central monitoring server for Prometheus and Grafana"
    profiles = ["net-server", "comp-small"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "build-01" = {
    description = "Build server for CI/CD pipelines"
    profiles = ["net-server", "comp-large", "disk-medium"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
    config = {
      "security.nesting" = "true"
    }
  }

  "build-02" = {
    description = "Secondary build server for CI/CD pipelines"
    profiles = ["net-server", "comp-large", "disk-medium"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
    config = {
      "security.nesting" = "true"
    }
  }

  "prox-01" = {
    description = "Proxy server for Traefik"
    profiles = ["net-server", "comp-small", "role-core"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "auth-01" = {
    description = "Authentication server with Authelia"
    profiles = ["net-server", "comp-small", "role-core"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "gate-01" = {
    description = "Gateway server for Cloudflare Tunnel and Wireguard"
    profiles = ["net-server", "comp-xsmall", "disk-small"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "media-01" = {
    description = "Media server for Jellyfin"
    profiles = ["net-server", "comp-medium", "disk-large"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
    target = "incus-03" // TODO: handle dynamic groups, currently bugged if we @has_gpu
    device = {
      data_dir = {
        type = "disk"
        source = "/mnt/storage/Media"
        path = "/data"
      }
      gpu = {
        type = "gpu"
        gputype = "physical"
        pci = "00:02.0"
        gid = "26"
      }
    }
  }

  "media-02" = {
    description = "Media organiser and orchestrator for Sonarr, Radarr, and Lidarr"
    profiles = ["net-server", "comp-medium", "disk-medium"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
    target = "incus-03"
    device = {
      data_dir = {
        type = "disk"
        source = "/mnt/storage/Media"
        path = "/data"
      }
    }
    // We need this for wireguard. TODO: Move this to it's own discrete container to avoid giving all media servers elevated privileges
    config = {
      "security.privileged"   = "true"
      "security.nesting"      = "true"
      "linux.kernel_modules"  = "wireguard"
    }
  }

  "stat-01" = {
    description         = "Metrics relay for incus-01 — scrapes local Incus, pushes to monitor-01"
    profiles            = ["net-server", "comp-xsmall", "net-infra"]
    type                = "container"
    image               = "cluster:nixos/custom/golden/lxc"
    target              = "incus-01"
    config = {
      "cluster.evacuate" = "stop"
    }
  }

  "stat-02" = {
    description          = "Metrics relay for incus-02 — scrapes local Incus, pushes to monitor-01"
    profiles             = ["net-server", "comp-xsmall", "net-infra"]
    type                 = "container"
    image                = "cluster:nixos/custom/golden/lxc"
    target               = "incus-02"
    config = {
      "cluster.evacuate" = "stop"
    }
  }

  "stat-03" = {
    description          = "Metrics relay for incus-03 — scrapes local Incus, pushes to monitor-01"
    profiles             = ["net-server", "comp-xsmall", "net-infra"]
    type                 = "container"
    image                = "cluster:nixos/custom/golden/lxc"
    target               = "incus-03"
    config = {
      "cluster.evacuate" = "stop"
    }
  }

  "util-01" = {
    description = "Utility server for miscellaneous other services"
    profiles = ["net-server", "comp-small", "disk-small"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "backup-01" = {
    description = "Backup server for storing snapshots and backups and exporting remotely"
    profiles = ["net-server", "comp-small", "disk-medium"]
    type     = "virtual-machine"
    image     = "cluster:nixos/custom/golden/vm"
  }

  "home-assistant" = {
    description         = "Home Assistant smart home controller"
    profiles            = ["net-server", "comp-medium", "disk-xlarge"]
    type                = "virtual-machine"
    image               = "cluster:nixos/custom/golden/vm"
    target              = "incus-02"
    skip_default_profile = true
    skip_sops_key        = true
    device = {
      root = {
        type = "disk"
        path = "/"
        pool = "pool-01"
        size = "40GiB"
      }
      zigbee = {
        type    = "usb"
        vendorid  = "1a86"
        productid = "55d4"
      }
    }
  }
}