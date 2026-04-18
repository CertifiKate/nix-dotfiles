{config, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];
  networking.hostName = "incus-02";
  nixpkgs.system = "x86_64-linux";

  CertifiKate.roles.server.incus_host = {
    enable = true;
    serverName = "incus-02";
    serverAddress = "192.168.10.202";

    # clusterToken = config.sops.secrets.incus_cluster_token.path;
    # clusterCertificate = config.sops.secrets.incus_cluster_cert.path;
    clusterAddress = "192.168.10.202:8443";

    external_interfaces = "ens18";
  };
}
