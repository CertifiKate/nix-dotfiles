# Common Incus configuration shared by bootstrap and member nodes
{
  config,
  pkgs,
  lib,
  inputs,
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
      serverMetricsPort = lib.mkOption {
        type = lib.types.int;
        default = 8444;
        description = "Port to bind metrics interface to";
      };
      serverGroups = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        default = [];
        description = "List of groups to assign the server to for cluster organization";
      };
      clusterInternalInterface = lib.mkOption {
        type = lib.types.str;
        description = "Network interface to use for cluster internal communication (Server MGMT VLAN)";
      };
      clusterUplinkInterface = lib.mkOption {
        type = lib.types.str;
        description = "Network interface to use for cluster uplink communication (Server VLAN)";
      };

      virtualIP = lib.mkOption {
        type = lib.types.submodule {
          options = {
            enable = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Enable keepalived for this host";
            };
            address = lib.mkOption {
              type = lib.types.str;
            };
            interface = lib.mkOption {
              type = lib.types.str;
              description = "Network interface to bind to";
            };
            priority = lib.mkOption {
              type = lib.types.int;
              default = 10;
              description = "VRRP priority (higher = master)";
            };
            routerId = lib.mkOption {
              type = lib.types.int;
              default = 99;
              description = "VRRP virtual router ID";
            };
          };
        };
      };

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
    # Allow us to use Wireguard within our containers
    boot.kernelModules = ["wireguard"];

    security.apparmor.enable = true;

    networking.useNetworkd = lib.mkForce true;

    networking = {
      vlans = {
        vlan10 = {
          id = 10;
          interface = cfg.clusterUplinkInterface;
        };
        vlan99 = {
          id = 99;
          interface = cfg.clusterUplinkInterface;
        };
      };
    };

    virtualisation.incus = {
      enable = true;
      package = pkgs.incus;
      ui.enable = true;
    };

    # Configure incus (without preseed)
    # Preseed seems to handle things a little bit differently than normal config set commands - below would fail in preseed on pre-bootstrapped hosts
    systemd.services.incus-configure = {
      description = "Configure Incus settings";
      after = ["incus.service"];
      wants = ["incus.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStart = pkgs.writeShellScript "incus-configure" ''
          until ${pkgs.incus}/bin/incus info > /dev/null 2>&1; do
            sleep 5
          done
          ${pkgs.incus}/bin/incus config set core.https_address=":${toString cfg.serverPort}"
          ${pkgs.incus}/bin/incus config set core.storage_buckets_address=":${toString cfg.serverBucketPort}"
          ${pkgs.incus}/bin/incus config set core.metrics_address=":${toString cfg.serverMetricsPort}"
          ${pkgs.incus}/bin/incus config set cluster.offline_threshold=60
        '';
      };
    };

    networking.nftables.enable = true;

    networking.firewall.interfaces = lib.mkMerge [
      # Allow accessing the Incus server ports on the cluster internal interface
      {
        "${cfg.clusterInternalInterface}".allowedTCPPorts = [cfg.serverPort cfg.serverBucketPort cfg.serverMetricsPort];
      }
      # Also allow on the virtual IP interface if it's different than the external interface (for floating IP setup)
      (lib.mkIf (cfg.virtualIP.enable && cfg.virtualIP.interface != cfg.clusterInternalInterface) {
        "${cfg.virtualIP.interface}".allowedTCPPorts = [cfg.serverPort cfg.serverBucketPort cfg.serverMetricsPort];
      })
      {
        # TODO: configure this somewhere so this doesn't race-condition with the net-infra bridge setup
        "net-infra".allowedTCPPorts = [cfg.serverMetricsPort];
      }
    ];

    networking.firewall.extraInputRules = ''
      ip protocol vrrp accept
    '';

    services.keepalived = lib.mkIf cfg.virtualIP.enable {
      enable = true;
      vrrpInstances.incus_ui = {
        interface = cfg.virtualIP.interface;
        virtualRouterId = cfg.virtualIP.routerId;
        priority = cfg.virtualIP.priority;
        virtualIps = [
          (lib.filterAttrs (n: v: v != null) {
            addr = cfg.virtualIP.address;
          })
        ];
      };
    };
  };
}
