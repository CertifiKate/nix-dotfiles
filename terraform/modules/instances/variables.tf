
variable "bootstrap_complete" {}
variable "profiles" {}

variable "host_keys_file" {}

variable "instances" {
  description = "Map of Incus instances to create with their configuration"
  type = map(object({
    description = optional(string)
    profiles    = list(string)
    type        = string
    image       = string
    target      = optional(string)
    config      = optional(map(string))
    device      = optional(map(any))
  }))
}