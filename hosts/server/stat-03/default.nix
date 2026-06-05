{...}: {
  CertifiKate.roles.server.metrics_relay = {
    enable = true;
    incusNode = "incus-03";
  };
  networking.hostName = "stat-03";

  networking.interfaces.eth1.ipv4.addresses = [{
    address = "10.10.0.23";
    prefixLength = 24;
  }];
}
