{
  vars,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
    ../default.nix

    inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd

    ../../../nixos/roles/physical/desktop/gnome
    ../../../nixos/roles/physical/desktop/cosmic
    ../../../nixos/roles/server/deployment-host
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/common
      ../../../home-manager/roles/personal
      ../../../home-manager/roles/desktop/gnome
      ../../../home-manager/roles/sops-management
    ];
  };

  networking.hostName = "aurora";
}
