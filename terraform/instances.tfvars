
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
    profiles = ["net-server", "comp-small", "disk-small"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
  }

  "auth-01" = {
    description = "Authentication server with Authelia"
    profiles = ["net-server", "comp-small", "disk-small"]
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
    profiles = ["net-server", "comp-medium", "disk-medium"]
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
    description = "Media downloader and support stack"
    profiles = ["net-server", "comp-medium", "disk-medium"]
    type     = "container"
    image     = "cluster:nixos/custom/golden/lxc"
    target = "incus-03" // Until we move media to NAS storage VM we're just bind mounting
    device = {
      data_dir = {
        type = "disk"
        source = "/mnt/storage/Media"
        path = "/data"
      }
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


}