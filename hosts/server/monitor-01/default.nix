{...}: {
  CertifiKate.roles.server.monitoring.enable = true;

  networking.hostName = "monitor-01";

  # Static IP on eth1 (net-infra bridge) to reach Incus metrics
  networking.interfaces.eth1 = {
    ipv4.addresses = [
      {
        address = "10.10.0.10";
        prefixLength = 24;
      }
    ];
  };
}
