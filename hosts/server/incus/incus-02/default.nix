{config, ...}: let
  inherit (config.flake.modules) nixos;

  server_name = "incus-02";
  cluster_internal_interface = "enp2s0";
  cluster_uplink_interface = "enp1s0";
  internal_address = "192.168.11.12";
  internal_gateway = "192.168.11.1";
in {
  configurations.nixos.incus-02 = {
    deployment.tags = ["incus"];

    module = {
      imports = [
        ./_hardware-configuration.nix
        nixos."modules/profiles/server"
        nixos."roles/server/incus/member"
      ];

      networking.hostName = server_name;

      CertifiKate.incus = {
        serverName = server_name;
        serverAddress = internal_address;
        clusterInternalInterface = cluster_internal_interface;
        clusterUplinkInterface = cluster_uplink_interface;
        zfsReplication = {
          enable = true;
          targets = [
            "syncoid@192.168.11.11:zpool/incus-replica"
            "syncoid@192.168.11.13:zpool/incus-replica"
          ];
        };
        virtualIP = {
          enable = true;
          address = "192.168.11.200";
          interface = cluster_internal_interface;
          priority = 102;
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
    };
  };
}
