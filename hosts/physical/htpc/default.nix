{
  vars,
  inputs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
    ../default.nix

    ../../../nixos/roles/physical/desktop/gaming
  ];

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/common
      ../../../home-manager/roles/personal
    ];
  };

  # Sets up HTPC to auto run steam big picture and auto login
  CertifiKate.roles.physical.desktop.gaming.autoStartSteam = true;
  CertifiKate.roles.physical.desktop.gaming.remotePlayClient = true;

  networking.hostName = "htpc";
}
