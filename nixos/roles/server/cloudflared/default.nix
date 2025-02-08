{
  pkgs,
  inputs,
  private,
  config,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
  project_tld = "${private.project_tld}";
in {
  sops.secrets."cloudflared_tunnel_cert" = {
    sopsFile = "${secretsPath}/secrets/proxy.yaml";
    owner = config.services.cloudflared.user;
    group = config.services.cloudflared.group;
  };

  services.cloudflared = {
    enable = true;
    tunnels = {
      "default-tunnel" = {
        credentialsFile = config.sops.secrets."cloudflared_tunnel_cert".path;
        default = "http_status:404";
        ingress = {
          "media.${project_tld}" = "https://localhost:443";
          "jellyseer.${project_tld}" = "https://localhost:443";
          "home.${project_tld}" = "https://localhost:443";
          "${project_tld}" = "https://localhost:443";
        };
        originRequest = {
          originServerName = "${project_tld}";
          noTLSVerify = true;
        };
      };
    };
  };
}
