output "bootstrap_complete" {
  value       = null_resource.bootstrap_complete.id
  depends_on  = [ null_resource.bootstrap_complete ]  # explicit here
}

output "profiles" {
  value = {
    net_server = incus_profile.net_server.name
    net_dmz = incus_profile.net_dmz.name
    default = incus_profile.default.name
    disk_medium = incus_profile.disk_medium.name
    disk_large = incus_profile.disk_large.name
    comp_xsmall = incus_profile.comp_xsmall.name
    comp_small = incus_profile.comp_small.name
    comp_medium = incus_profile.comp_medium.name
    comp_large = incus_profile.comp_large.name
    comp_xlarge = incus_profile.comp_xlarge.name
  }
}