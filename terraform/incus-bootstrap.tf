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


# Network profiles
resource "incus_profile" "net_vlan10" {
  name    = "net-vlan10"
  device {
    name = "net_vlan10"
    type    = "nic"
    properties = {
      nictype = "bridged"
      parent  = "enp1s0"
      vlan = "10"
      # "vlan.tagged" = "10"
    }
  }
}

# resource "incus_profile" "net_vlan99" {
#   name    = "net-vlan99"
#   device {
#     name = "net_vlan99"
#     type    = "nic"
#     properties = {
#       nictype = "macvlan"
#       parent  = "vlan99"
#       mode    = "bridge"
#     }
#   }
# }

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
