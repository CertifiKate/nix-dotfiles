{
  vars,
  inputs,
  lib,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
    ../default.nix

    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd

    ../../../nixos/roles/physical/desktop/gnome
    ../../../nixos/roles/physical/desktop/cosmic
    ../../../nixos/roles/server/common/options.nix
    ../../../nixos/roles/server/services/deployment-host
  ];
  CertifiKate.roles.server.deployment_host.enable = true;

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/common
      ../../../home-manager/roles/personal
      ../../../home-manager/roles/desktop/gnome
      ../../../home-manager/roles/sops-management
      ../../../home-manager/roles/ansible-controller/ansible-controller.nix
    ];
  };

  networking.hostName = "aurora";
}
