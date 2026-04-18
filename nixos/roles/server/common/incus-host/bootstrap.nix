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
    };
  };
}
