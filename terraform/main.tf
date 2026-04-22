module "bootstrap" {
  source = "./modules/bootstrap"

  cluster_address = var.cluster_address
  nixos_golden_image_vers = var.nixos_golden_image_vers
}

module "instances" {
  source = "./modules/instances"

  bootstrap_complete = module.bootstrap.bootstrap_complete

  host_keys_file = var.host_keys_file
  instances = var.instances
  profiles = module.bootstrap.profiles
}