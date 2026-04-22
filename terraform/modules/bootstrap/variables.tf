variable "cluster_address" {
  description = "The address of the entire cluster. Used for non-node specific functions"
  type = string
}

variable "nixos_golden_image_vers" {
  type = number
  default = 1
}
