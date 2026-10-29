# Join existing Incus cluster
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."roles/server/incus/member" = {config, ...}: let
    cfg = config.CertifiKate.incus;
  in {
    imports = [nixos."roles/server/incus/incus-host"];

    virtualisation.incus = {
      enable = true;
      preseed.cluster =
        {
          enabled = true;
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
