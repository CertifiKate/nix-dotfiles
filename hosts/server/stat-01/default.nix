{...}: {
  CertifiKate.roles.server.metrics_relay = {
    enable = true;
    incusNode = "incus-01";
  };
  networking.hostName = "stat-01";

  networking.interfaces.eth1.ipv4.addresses = [
    {
      address = "10.10.0.21";
      prefixLength = 24;
    }
  ];
}
