# Common Incus configuration shared by bootstrap and member nodes
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.CertifiKate.roles.server.incus_host;
in {
  options = {
    CertifiKate.roles.server.incus_host = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      # Shared configuration options
      serverName = lib.mkOption {
        type = lib.types.str;
        description = "Incus server name for cluster identification";
      };
      serverAddress = lib.mkOption {
        type = lib.types.str;
        description = "Address to bind interface to";
      };
      serverPort = lib.mkOption {
        type = lib.types.int;
        default = 8443;
        description = "Port to bind interface to";
      };
      serverBucketPort = lib.mkOption {
        type = lib.types.int;
        default = 8334;
        description = "Port to bind storage buckets interface to";
      };

      external_interfaces = lib.mkOption {type = lib.types.str;};

      # Member specific
      clusterToken = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      clusterCertificate = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      clusterAddress = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
    };
  };

  config = lib.mkIf cfg.enable {
    security.apparmor.enable = true;

    networking.useNetworkd = lib.mkForce true;

    networking = {
      vlans = {
        vlan10 = {
          id = 10;
          interface = cfg.external_interfaces;
        };
        vlan99 = {
          id = 99;
          interface = cfg.external_interfaces;
        };
      };
    };

    virtualisation.incus = {
      enable = true;
      package = pkgs.incus;
      ui.enable = true;
      preseed = {
        config = {
          "core.https_address" = "${cfg.serverAddress}:${toString cfg.serverPort}";
          "core.storage_buckets_address" = "${cfg.serverAddress}:${toString cfg.serverBucketPort}";
        };
      };
    };

    networking.nftables.enable = true;
    networking.firewall.allowedTCPPorts = [cfg.serverPort cfg.serverBucketPort];
  };
}
