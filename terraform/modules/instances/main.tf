terraform {
  required_providers {
    incus = {
      source  = "lxc/incus"
      version = "~> 1.0"
    }
    null = {
      source  = "hashicorp/null"
      version = "~> 3.0"
    }
  }
}

# Create instances based on the provided configuration
resource "incus_instance" "instances" {
  # Make sure the images are deployed first

  for_each = var.instances

  name  = each.key
  image = each.value.image
  type  = each.value.type
  description = each.value.description
  # TODO: Only on creation!
  running = true

  # TODO: Handle location for groups? based on capabilities?
  # location = ""

  profiles = concat([
    "default",
  ], each.value.profiles)

  # Pass in our custom config, but also pass through the cloud init to set hostnames
  config = merge(each.value.config, {
    "cloud-init.user-data" = <<-EOT
      #cloud-config
      hostname: ${each.key}
      manage_etc_hosts: true
      preserve_hostname: false
    EOT
  })
}

locals {
  host_keys = sensitive(yamldecode(file(var.host_keys_file)))
}

resource "null_resource" "sops_key" {
  for_each = var.instances

  depends_on = [
    incus_instance.instances,
  ]

  triggers = {
    # Re-deploy when instance chances (which has new mac address)
    mac_address = incus_instance.instances[each.key].mac_address
  }
  

  provisioner "local-exec" {
    command     = <<-EOT
      TMPFILE=$(mktemp)
      trap "rm -f $TMPFILE" EXIT
      echo '${local.host_keys[each.key]}' > $TMPFILE
      incus file push $TMPFILE cluster:${each.key}/etc/sops-age.txt --mode 0600
    EOT
  }
}