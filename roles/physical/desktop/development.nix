{config, ...}: let
  inherit (config.meta) user;
in {
  flake.modules.nixos."roles/physical/desktop/development" = {
    virtualisation.docker.enable = true;

    users.users.${user}.extraGroups = ["docker"];
  };
}
