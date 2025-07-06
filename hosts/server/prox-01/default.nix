{...}: {
  imports = [
    ../../../nixoa/roles/server/cloudflared
    ../../../nixos/roles/server/proxy
  ];

  networking.hostName = "prox-01";
}
