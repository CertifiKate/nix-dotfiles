{
  pkgs,
  inputs,
  private,
  config,
  lib,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
  project_tld = "${private.project_tld}";
in {
  config = lib.mkMerge [
    (lib.mkIf config.CertifiKate.roles.server.cloudflared.enable {
      sops.secrets."cloudflared_tunnel_cert" = {
        sopsFile = "${secretsPath}/secrets/proxy.yaml";
      };

      sops.secrets."cloudflared_tunnel_creation_cert" = {
        sopsFile = "${secretsPath}/secrets/proxy.yaml";
      };

      services.cloudflared = {
        enable = true;
        tunnels = {
          "default-tunnel" = {
            certificateFile = config.sops.secrets."cloudflared_tunnel_creation_cert".path;
            credentialsFile = config.sops.secrets."cloudflared_tunnel_cert".path;
            default = "http_status:404";
            ingress = {
              "media.${project_tld}" = "https://localhost:443";
              "jellyseer.${project_tld}" = "https://localhost:443";
              "home.${project_tld}" = "https://localhost:443";
              "auth.${project_tld}" = "https://localhost:443";
              "${project_tld}" = "https://localhost:443";
            };
            originRequest = {
              originServerName = "${project_tld}";
              noTLSVerify = true;
            };
          };
        };
      };
    })
  ];
}
