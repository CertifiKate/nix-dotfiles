{
  vars,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
    ../default.nix

    ../../../nixos/roles/physical/desktop/gnome
    ../../../nixos/roles/physical/desktop/cosmic
    ../../../nixos/roles/server/deployment-host
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/common
      ../../../home-manager/roles/personal
      ../../../home-manager/roles/desktop/gnome
    ];
  };

  networking.hostName = "cosmos";
}
