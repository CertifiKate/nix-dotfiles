# Bootstrap Incus infrastructure: storage, networks, profiles, image sources


# === Storage pools
# Node specific storage pool (ZFS)
resource "incus_storage_pool" "zfs_pool_incus_01" {
  name   = "zfs-pool-01"
  driver = "zfs"
  config = {
    size = "100GiB"
  }
  target = "incus-01"
}

# Cluster specific storage pool (ZFS)
resource "incus_storage_pool" "zfs_pool" {
  depends_on = [ incus_storage_pool.zfs_pool_incus_01 ]
  name   = "zfs-pool-01"
  driver = "zfs"
}


# Set up the base level networks for the cluster
resource "incus_network" "net_vlan10_incus01" {
  name = "net-vlan10"
  target = "incus-01"
  type = "macvlan"
  config = {
    "parent" = "vlan10"
  }
}

resource "incus_network" "net_vlan99_incus01" {
  name = "net-vlan99"
  target = "incus-01"
  type = "macvlan"
  config = {
    "parent" = "vlan99"
  }

}

resource "incus_network" "net_vlan10" {
  depends_on = [ incus_network.net_vlan10_incus01 ]
  type = "macvlan"
  name = "net-vlan10"
}

resource "incus_network" "net_vlan99" {
  depends_on = [ incus_network.net_vlan99_incus01 ]
  type = "macvlan"
  name = "net-vlan99"
}


resource "incus_profile" "net_server" {
  name    = "net-server"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "${incus_network.net_vlan10.name}"
    }
  }
}


resource "incus_profile" "net_dmz" {
  name    = "net-dmz"
  device {
    name = "eth0"
    type = "nic"
    properties = {
      network = "${incus_network.net_vlan99.name}"
    }
  }
}



# Default profile with root disk on ZFS pool
resource "incus_profile" "default" {
  name = "default"
  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = incus_storage_pool.zfs_pool.name
      size = "4GiB"
    }
  }
}

# Compute profiles
resource "incus_profile" "comp_xsmall" {
  name = "comp-xsmall"
  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "1GiB"
  }
}

resource "incus_profile" "comp_small" {
  name = "comp-small"
  config = {
    "limits.cpu"    = "1"
    "limits.memory" = "2GiB"
  }
}

resource "incus_profile" "comp_medium" {
  name = "comp-medium"
  config = {
    "limits.cpu"    = "2"
    "limits.memory" = "4GiB"
  }
}

resource "incus_profile" "comp_large" {
  name = "comp-large"
  config = {
    "limits.cpu"    = "4"
    "limits.memory" = "8GiB"
  }
}

resource "incus_profile" "comp_xlarge" {
  name = "comp-xlarge"
  config = {
    "limits.cpu"    = "8"
    "limits.memory" = "16GiB"
  }
}

# Setup an S3 bucket for storing Terraform State
resource "incus_storage_bucket" "s3_terraform_state" {
  name = "terraform-state"
  pool = incus_storage_pool.zfs_pool.name
}

resource "incus_storage_bucket_key" "s3_terraform_state_object" {
  name = "terraform.tfstate"
  pool = incus_storage_pool.zfs_pool.name
  role = "admin"
  storage_bucket = incus_storage_bucket.s3_terraform_state.name
}

resource "null_resource" "incus_remote" {
  provisioner "local-exec" {
    command = <<-EOT
      incus remote add cluster ${var.cluster_address} --accept-certificate 2>/dev/null || true
    EOT
  }
}


resource "null_resource" "golden_image_vm" {
  triggers = {
    image_version = var.nixos_golden_image_vers
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash"]
    command     = "${path.module}/scripts/push-golden-vm.sh"
    environment = {
      IMAGE_ALIAS = "nixos/custom/golden/vm"
      FLAKE_PATH  = "${path.module}/.."
    }
  }
}

resource "null_resource" "golden_image_lxc" {
  # Just stops it running in parallel!
  depends_on = [null_resource.golden_image_vm]

  triggers = {
    image_version = var.nixos_golden_image_vers
  }

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash"]
    command     = "${path.module}/scripts/push-golden-lxc.sh"
    environment = {
      IMAGE_ALIAS = "nixos/custom/golden/lxc"
      FLAKE_PATH  = "${path.module}/.."
    }
  }
}