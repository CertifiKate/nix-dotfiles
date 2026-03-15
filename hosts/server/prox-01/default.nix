{...}: {
  CertifiKate.roles.server.proxy.enable = true;
  CertifiKate.roles.server.cloudflared.enable = true;

  networking.hostName = "prox-01";
}
