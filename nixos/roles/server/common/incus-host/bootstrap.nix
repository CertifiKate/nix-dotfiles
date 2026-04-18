# Bootstrap first Incus cluster node
{
  config,
  pkgs,
  lib,
  options,
  ...
}: let
  cfg = config.CertifiKate.roles.server.incus_host;
in {
  imports = [./common.nix];

  config = lib.mkIf cfg.enable {
    virtualisation.incus.preseed = {
      cluster = {
        enabled = true;
        server_name = cfg.serverName;
      };
      storage_pools = [
        {
          name = "default";
          driver = "dir";
        }
      ];
      networks = [
        {
          name = "vlan10";
          type = "macvlan";
          config = {
            parent = cfg.external_interfaces;
            vlan = 10;
          };
        }
        {
          name = "vlan50";
          type = "macvlan";
          config = {
            parent = cfg.external_interfaces;
            vlan = 50;
          };
        }
        {
          name = "vlan99";
          type = "macvlan";
          config = {
            parent = cfg.external_interfaces;
            vlan = 99;
          };
        }
      ];
      profiles = [
        # Network profiles
        {
          name = "net-vlan10";
          devices = {
            eth0 = {
              type = "nic";
              nictype = "macvlan";
              parent = "eth0.10";
              mode = "bridge";
            };
          };
        }
        {
          name = "net-vlan50";
          devices = {
            eth0 = {
              type = "nic";
              nictype = "macvlan";
              parent = "eth0.50";
              mode = "bridge";
            };
          };
        }
        {
          name = "net-vlan99";
          devices = {
            eth0 = {
              type = "nic";
              nictype = "macvlan";
              parent = "eth0.99";
              mode = "bridge";
            };
          };
        }
        # Compute profiles
        {
          name = "comp-small";
          config = {
            "limits.cpu" = "1";
            "limits.memory" = "1GiB";
          };
        }
        {
          name = "comp-medium";
          config = {
            "limits.cpu" = "2";
            "limits.memory" = "2GiB";
          };
        }
        {
          name = "comp-large";
          config = {
            "limits.cpu" = "4";
            "limits.memory" = "4GiB";
          };
        }
      ];
    };
  };
}
