
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
}