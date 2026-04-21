
# Create instances based on the provided configuration
resource "incus_instance" "instances" {
  for_each = var.instances

  name  = each.key
  image = each.value.image != null ? each.value.image : var.default_image
  type  = each.value.type
  description = each.value.description

  # TODO: Handle location for groups? based on capabilities?
  # location = ""

  profiles = concat([
    "default",
  ], each.value.profiles)

  config = each.value.config
}

locals {
  host_keys = sensitive(yamldecode(file(var.host_keys_file)))
}

resource "null_resource" "sops_key" {
  for_each = var.instances

  depends_on = [
    incus_instance.instances,
    null_resource.incus_remote,
  ]

  triggers = {
    instance_id = incus_instance.instances[each.key].name
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