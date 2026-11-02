#
# Coder server for dev workspaces. See docs/coder-workspaces.md
#
{config, ...}: let
  inherit (config.meta) secretsPath private;
in {
  homelab.routes.coder = {
    host = "coder";
    dest = "http://coder-01.srv:3000";
    rules = [
      {
        policy = "bypass";
      }
    ];
    dashboard = {
      name = "Coder Workspaces";
      description = "Self-hosted development environments";
      icon = "sh-coder";
      group = "Development";
    };
  };

  flake.modules.nixos."roles/server/services/coder" = {
    config,
    lib,
    ...
  }: let
    project_dir = "/var/lib/coder";
    incus_dir = "${project_dir}/incus";
    token_file = "${project_dir}/template-token";

    # Each folder is a template, named after the folder
    templates = lib.attrNames (lib.filterAttrs (_: type: type == "directory") (builtins.readDir ./templates));
  in {
    CertifiKate.persist.directories = [
      project_dir
      "/var/lib/postgresql"
    ];
    CertifiKate.persist.localDirectories = ["/var/cache/coder"];

    networking.firewall.allowedTCPPorts = [3000];

    sops.secrets."coder_client_key" = {
      sopsFile = "${secretsPath}/secrets/coder.yaml";
      path = "${incus_dir}/client.key";
      owner = "coder";
    };

    sops.secrets."coder_oidc_client_secret".sopsFile = "${secretsPath}/secrets/coder.yaml";
    sops.templates."coder.env" = {
      owner = "coder";
      content = "CODER_OIDC_CLIENT_SECRET=${config.sops.placeholder."coder_oidc_client_secret"}\n";
    };

    systemd.tmpfiles.rules = [
      "d ${incus_dir} 700 coder coder"
      "L+ ${incus_dir}/client.crt - - - - ${secretsPath}/coder-client.crt"
    ];

    services.coder = {
      enable = true;
      accessUrl = "https://coder.${private.project_tld}";
      listenAddress = "0.0.0.0:3000";
      environment.file = config.sops.templates."coder.env".path;
      environment.extra = {
        CODER_OIDC_ISSUER_URL = "https://auth.${private.project_tld}";
        CODER_OIDC_CLIENT_ID = "coder";
        CODER_OIDC_SCOPES = "openid,profile,email,groups";
        CODER_OIDC_SIGN_IN_TEXT = "Authelia";
        CODER_OAUTH2_GITHUB_DEFAULT_PROVIDER_ENABLE = "false";

        CODER_TELEMETRY_ENABLE = "false";
        CODER_BLOCK_DIRECT = "true";
        CODER_MAX_ADMIN_TOKEN_LIFETIME = "87600h"; # Bit gross, but allows us to push templates to Coder without having to refresh the token every 24h
      };
    };

    systemd.services.coder-template = {
      description = "Push the workspace templates to Coder";
      after = ["coder.service"];
      requires = ["coder.service"];
      wantedBy = ["multi-user.target"];
      path = [config.services.coder.package];
      environment.CODER_URL = "http://127.0.0.1:3000";
      unitConfig = {
        ConditionPathExists = token_file;
        StartLimitIntervalSec = 0;
      };
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "coder";
        EnvironmentFile = token_file;
        Restart = "on-failure";
        RestartSec = 10;
      };
      script =
        lib.concatMapStrings (name: ''
          coder templates push ${name} --directory ${./templates}/${name} --yes
          coder templates edit ${name} --default-ttl 2h --yes
        '')
        templates;
    };
  };
}
