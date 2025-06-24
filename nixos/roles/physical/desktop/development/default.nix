{vars, ...}: {
  virtualisation.docker.enable = true;

  users.users.${vars.user}.extraGroups = ["docker"];
}
