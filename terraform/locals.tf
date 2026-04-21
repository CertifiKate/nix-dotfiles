locals {
  # TODO: Pull from remote?
  existing_profiles = toset([
    incus_profile.default.name,
    incus_profile.net_server.name,
    incus_profile.net_dmz.name,
    incus_profile.comp_xsmall.name,
    incus_profile.comp_small.name,
    incus_profile.comp_medium.name,
    incus_profile.comp_large.name,
    incus_profile.comp_xlarge.name,
  ])

  requested_profiles = toset(flatten([
    for inst in var.instances : inst.profiles
  ]))

  unknown_profiles = setsubtract(local.requested_profiles, local.existing_profiles)
}