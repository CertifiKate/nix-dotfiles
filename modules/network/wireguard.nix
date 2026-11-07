#
# WireGuard connections imported into NetworkManager from the host's sops file
# Each name in CertifiKate.wireguard.interfaces reads a wg-quick config from `wireguard/<name>`
# in CertifiKate.secrets.hostSopsFile
#
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."modules/network/wireguard" = {
    config,
    lib,
    ...
  }: let
    interfaces = config.CertifiKate.wireguard.interfaces;
  in {
    imports = [nixos."modules/secrets/host"];

    options.CertifiKate.wireguard.interfaces = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "WireGuard connections to import, by name in the host's sops file";
    };

    config = {
      # nmcli names the connection after the file, and wants a .conf
      sops.secrets = lib.listToAttrs (map (name:
        lib.nameValuePair "wireguard/${name}" {
          sopsFile = config.CertifiKate.secrets.hostSopsFile;
          path = "/run/secrets/wireguard/${name}.conf";
          restartUnits = ["wireguard-${name}.service"];
        })
      interfaces);

      systemd.services = lib.listToAttrs (map (name:
        lib.nameValuePair "wireguard-${name}" {
          wantedBy = ["multi-user.target"];
          requires = ["NetworkManager.service"];
          after = ["NetworkManager.service"];
          path = [config.networking.networkmanager.package];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
          };
          script = ''
            nmcli connection delete id ${name} || true
            nmcli connection import type wireguard file ${config.sops.secrets."wireguard/${name}".path}
            nmcli connection modify id ${name} connection.autoconnect no
          '';
        })
      interfaces);
    };
  };
}
