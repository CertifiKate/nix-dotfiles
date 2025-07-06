{...}: {
  imports = [
    ../../../nixos/roles/server/minecraft
  ];

  networking.hostName = "mine-01";
}
