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
    ../../../nixos/roles/physical/desktop/gaming
    ../../../nixos/roles/physical/desktop/cosmic
    ../../../nixos/roles/server/common/options.nix
    ../../../nixos/modules/sops-admin.nix
  ];

  home-manager = {
    users.${vars.user} = {
      imports = [
        ../../../home-manager/common
        ../../../home-manager/roles/personal
        ../../../home-manager/roles/desktop/gnome
        ../../../home-manager/roles/sops-management
        ../../../home-manager/roles/ansible-controller/ansible-controller.nix
        ../../../home-manager/roles/deploy-host
        ../../../home-manager/roles/rdp-client
      ];
      CertifiKate.rdpClient.hosts = ["mgmt-01.srv"];
    };
  };

  networking.hostName = "aurora";
}
