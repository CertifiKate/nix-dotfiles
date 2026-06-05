{...}: {
  CertifiKate.roles.server.metrics_relay = {
    enable = true;
    incusNode = "incus-02";
  };
  networking.hostName = "stat-02";

  networking.interfaces.eth1.ipv4.addresses = [{
    address = "10.10.0.22";
    prefixLength = 24;
  }];
}
