{...}: {
  imports = [
    ../../../nixos/roles/server/auth
  ];

  networking.hostName = "auth-01";
}
