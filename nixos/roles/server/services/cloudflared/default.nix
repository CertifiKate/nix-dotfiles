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
  serviceName = "cloudflared-tunnel-default-tunnel";
  credDir = "/run/credentials/${serviceName}.service";
  setupCreds = pkgs.writeShellScript "cloudflared-setup-creds" ''
    install -d -m 0700 -o cloudflared -g cloudflared ${credDir}
    install -m 0400 -o cloudflared -g cloudflared \
      ${config.sops.secrets."cloudflared_tunnel_cert".path} \
      ${credDir}/credentials.json
    install -m 0400 -o cloudflared -g cloudflared \
      ${config.sops.secrets."cloudflared_tunnel_creation_cert".path} \
      ${credDir}/cert.pem
  '';
in {
  config = lib.mkMerge [
    (lib.mkIf config.CertifiKate.roles.server.cloudflared.enable {
      users.users.cloudflared = {
        isSystemUser = true;
        group = "cloudflared";
      };
      users.groups.cloudflared = {};

      sops.secrets."cloudflared_tunnel_cert" = {
        sopsFile = "${secretsPath}/secrets/proxy.yaml";
        owner = "cloudflared";
      };

      sops.secrets."cloudflared_tunnel_creation_cert" = {
        sopsFile = "${secretsPath}/secrets/proxy.yaml";
        owner = "cloudflared";
      };

      systemd.services.${serviceName} = {
        serviceConfig = {
          DynamicUser = lib.mkForce false;
          User = "cloudflared";
          Group = "cloudflared";
          ExecStartPre = lib.mkBefore ["+${setupCreds}"];
        };
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
