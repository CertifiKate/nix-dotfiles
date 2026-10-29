# Bootstrap first Incus cluster node
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."roles/server/incus/bootstrap" = {config, ...}: let
    cfg = config.CertifiKate.incus;
  in {
    imports = [nixos."roles/server/incus/incus-host"];

    virtualisation.incus.preseed = {
      cluster = {
        enabled = true;
        server_name = cfg.serverName;
      };
    };
  };
}
