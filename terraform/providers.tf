terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "1.0.2"
    }
  }
}

provider "incus" {
  generate_client_certificates = true
  accept_remote_certificate = true
  default_remote = "cluster"

  # Non node-specific remote  
  remote {
    name = "cluster"
    address = var.cluster_address
  }

  remote {
    name    = "incus-01"
    address = var.cluster_address
  }
  remote {
    name    = "incus-02"
    address = var.cluster_address
  }
  remote {
    name    = "incus-03"
    address = var.cluster_address
  }

}
