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
    pkgs,
    ...
  }: let
    project_dir = "/var/lib/coder";
    incus_dir = "${project_dir}/incus";
    token_file = "${project_dir}/template-token";

    templates = {
      lightweight = {
        display_name = "Lightweight";
        description = "Starts in seconds, with no root. A fresh container each start, with only your home kept. No Docker";
        icon = "/icon/debian.svg";
      };
      devcontainers = {
        display_name = "Dev Containers";
        description = "Docker and sudo, and starts the repo's devcontainer.json. The whole machine is kept between stops";
        icon = "/icon/docker.svg";
      };
    };

    # Templates link to the shared templates/common.tf. Coder only uploads the folder, so resolve them
    templateDir = name:
      pkgs.runCommand "coder-template-${name}" {} ''
        cp -rL ${./templates}/${name} $out
      '';
  in {
    CertifiKate.persist.directories = [
      project_dir
      "/var/lib/postgresql"
    ];
    CertifiKate.persist.localDirectories = ["/var/cache/coder"];

    networking.firewall.allowedTCPPorts = [3000];

    # Make the coder package available for general configuration
    environment.systemPackages = [config.services.coder.package];

    sops.secrets."coder_client_key" = {
      sopsFile = "${secretsPath}/secrets/coder.yaml";
      path = "${incus_dir}/client.key";
      owner = "coder";
    };

    sops.secrets."coder_oidc_client_secret".sopsFile = "${secretsPath}/secrets/coder.yaml";

    sops.secrets."coder_github_client_id".sopsFile = "${secretsPath}/secrets/coder.yaml";
    sops.secrets."coder_github_client_secret".sopsFile = "${secretsPath}/secrets/coder.yaml";

    sops.templates."coder.env" = {
      owner = "coder";
      content = ''
        CODER_OIDC_CLIENT_SECRET=${config.sops.placeholder."coder_oidc_client_secret"}
        CODER_EXTERNAL_AUTH_0_CLIENT_ID=${config.sops.placeholder."coder_github_client_id"}
        CODER_EXTERNAL_AUTH_0_CLIENT_SECRET=${config.sops.placeholder."coder_github_client_secret"}
      '';
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
        CODER_EXTERNAL_AUTH_0_ID = "github";
        CODER_EXTERNAL_AUTH_0_TYPE = "github";
        CODER_EXTERNAL_AUTH_0_DISPLAY_NAME = "GitHub";
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
      script = lib.concatStrings (lib.mapAttrsToList (name: t: ''
          coder templates push ${name} --directory ${templateDir name} --yes
          coder templates edit ${name} --yes \
            --display-name ${lib.escapeShellArg t.display_name} \
            --description ${lib.escapeShellArg t.description} \
            --icon ${lib.escapeShellArg t.icon} \
            --default-ttl 2h
        '')
        templates);
    };
  };
}
