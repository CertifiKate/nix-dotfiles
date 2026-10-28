{
  inputs,
  vars,
  ...
}: {
  imports = [
    inputs.home-manager.nixosModules.home-manager
    ../../../nixos/modules/home-manager.nix
  ];
  CertifiKate.roles.server.remote_desktop.enable = true;

  home-manager = {
    users.${vars.user}.imports = [
      ../../../home-manager/base
    ];
  };

  networking.hostName = "mgmt-01";
}
