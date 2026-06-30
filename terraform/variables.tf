variable "default_image_vm" {
  description = "Default image to use for instances if not specified"
  type        = string
  default    = ""
}

variable "default_image_lxc" {
  description = "Default image to use for instances if not specified"
  type        = string
  default    = ""
}

variable "host_keys_file" {
  description = "Path to YAML file containing per-host age keys"
  type        = string
}

variable "cluster_address" {
  description = "The address of the entire cluster. Used for non-node specific functions"
  type = string
}

variable "cluster_s3_endpoint" {
  description = "The S3 endpoint for the cluster's object storage. Used for Terraform state storage and backup server remote export"
  type = string
}

variable "nixos_golden_image_vers" {
  type = number
  default = 1
}

variable "instances" {
  description = "Map of Incus instances to create"
  type = map(object({
    profiles = list(string)
    type = string

    image = string
    description          = optional(string, null)
    config               = optional(map(string), {})
    target               = optional(string, null)
    device               = optional(map(map(string)), {})
    skip_default_profile = optional(bool, false)
    skip_sops_key        = optional(bool, false)
  }))

  validation {
    condition = alltrue([
      for k, v in var.instances :
      contains(["container", "virtual-machine"], v.type)
    ])
    error_message = "type must be 'container' or 'virtual-machine'"
  }
}