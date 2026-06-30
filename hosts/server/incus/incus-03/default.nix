{...}: let
  server_name = "incus-03";
  cluster_internal_interface = "enp1s0"; # Yes, it annoys me too that this is the opposite of the other two...
  cluster_uplink_interface = "enp0s31f6";
  internal_address = "192.168.11.13";
  internal_gateway = "192.168.11.1";
in {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];

  networking.hostName = server_name;

  CertifiKate.roles.server.incus_host = {
    enable = true;
    serverName = server_name;
    serverAddress = internal_address;
    clusterInternalInterface = cluster_internal_interface;
    clusterUplinkInterface = cluster_uplink_interface;
    virtualIP = {
      enable = true;
      address = "192.168.11.200";
      interface = cluster_internal_interface;
      priority = 103;
    };
  };

  networking.interfaces = {
    "${cluster_uplink_interface}" = {
      useDHCP = false;
    };
    "${cluster_internal_interface}" = {
      ipv4.addresses = [
        {
          address = internal_address;
          prefixLength = 24;
        }
      ];
    };
  };
  networking.defaultGateway = {
    address = internal_gateway;
    interface = cluster_internal_interface;
  };
}
