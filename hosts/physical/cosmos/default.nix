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
    ../../../nixos/roles/physical/desktop/gaming
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ./home.nix
      ../../../home-manager/common
      ../../../home-manager/roles/desktop/gnome
    ];
  };

  # Most of the time I'm using this machine as a gaming desktop, so auto start in steam big picture
  CertifiKate.roles.physical.desktop.gaming.autoStartSteam = true;

  networking.hostName = "cosmos";
}
