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
    ../../../nixos/roles/server/common/options.nix
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/common
      ../../../home-manager/roles/personal
      ../../../home-manager/roles/desktop/gnome
      ../../../home-manager/roles/deploy-host
    ];
  };

  networking.hostName = "cosmos";
}
