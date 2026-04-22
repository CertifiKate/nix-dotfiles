{lib, ...}: {
  CertifiKate.roles.server.nix_builder.enable = true;
  # Disable remote building (bc this should be doing remote building!!)
  CertifiKate.remoteBuilders.enable = lib.mkForce false;

  networking.hostName = "build-02";
}
