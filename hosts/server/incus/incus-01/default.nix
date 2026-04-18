{modulesPath, ...}: let
  server_name = "incus-01";
  external_interface = "enp1s0";
  server_address = "192.168.0.6";
  gateway_address = "192.168.0.1";
in {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];

  networking.hostName = server_name;

  CertifiKate.roles.server.incus_host = {
    enable = true;
    serverName = server_name;
    serverAddress = server_address;
    external_interfaces = external_interface;
  };

  networking.interfaces = {
    "${external_interface}" = {
      ipv4.addresses = [
        {
          address = server_address;
          prefixLength = 24;
        }
      ];
    };
  };
  networking.defaultGateway = {
    address = gateway_address;
    interface = external_interface;
  };
}
