{
  lib,
  vars,
  pkgs,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
    ../default.nix

    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd

    ../../../modules/nixos/roles/physical/desktop/gnome
    ../../../modules/nixos/roles/physical/desktop/cosmic
    ../../../modules/nixos/roles/server/deployment-host
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ../../../modules/home-manager/common
      ../../../modules/home-manager/roles/personal
      ../../../modules/home-manager/roles/desktop/gnome
      ../../../modules/home-manager/roles/sops-management
    ];
  };

  networking.hostName = "aurora";
}
