{...}: {
  imports = [
    ../../../nixos/modules/backup/server
  ];

  networking.hostName = "backup-01";
}
