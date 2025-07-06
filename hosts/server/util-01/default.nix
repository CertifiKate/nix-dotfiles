{...}: {
  imports = [
    ../../../nixos/roles/server/budget
  ];

  networking.hostName = "util-01";
}
