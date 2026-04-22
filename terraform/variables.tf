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

variable "nixos_golden_image_vers" {
  type = number
  default = 1
}

variable "instances" {
  description = "Map of Incus instances to create"
  type = map(object({
    profiles = list(string)
    type     = string

    image    = string
    description = optional(string)
    config   = optional(map(string), {})
  }))

  validation {
    condition = alltrue([
      for k, v in var.instances :
      contains(["container", "virtual-machine"], v.type)
    ])
    error_message = "type must be 'container' or 'virtual-machine'"
  }
}