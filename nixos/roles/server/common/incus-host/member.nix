# Join existing Incus cluster
{
  config,
  pkgs,
  lib,
  ...
}: let
  cfg = config.CertifiKate.roles.server.incus_host;
in {
  imports = [./common.nix];

  config = lib.mkIf cfg.enable {
    virtualisation.incus = {
      enable = true;
      preseed.cluster =
        {
          enabled = true;
          server_address = cfg.clusterAddress;
        }
        // (
          if cfg.clusterToken != null && cfg.clusterCertificate != null
          then {
            cluster_token = builtins.readFile cfg.clusterToken;
            cluster_certificate = builtins.readFile cfg.clusterCertificate;
          }
          else {}
        );
    };
  };
}
