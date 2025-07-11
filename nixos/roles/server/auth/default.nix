{
  pkgs,
  inputs,
  config,
  lib,
  private,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";
  base_dn = "${private.ldap_base_dn}";
  smtp_sender = "${private.smtp_sender}";
  smtp_address = "smtp://${private.smtp_address}:587";

  project_dir = "/services/authelia";
  config_dir = "${project_dir}/config";
  ldap_dir = "${project_dir}/ldap";
  data_dir = "${project_dir}/data";
in {
  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${project_dir}"
      "/var/lib/lldap"
    ];
  };

  environment.systemPackages = with pkgs; [
    authelia
  ];

  networking.firewall.allowedTCPPorts = [
    9091 # Authelia
    3890 # LDAP
    17170 # LLDAP Web UI
  ];

  # Allow traefik to access config data dir
  systemd = {
    tmpfiles.rules = [
      "d ${config_dir} 700 authelia authelia"
      "d ${data_dir} 700 authelia authelia"
      "d ${ldap_dir} 700 lldap lldap"
    ];
  };

  sops.secrets."authelia_jwt_secret" = {
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };
  sops.secrets."authelia_session_secret" = {
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };
  sops.secrets."authelia_storage_key" = {
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };
  sops.secrets."authelia_ldap_password" = {
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };
  sops.secrets."smtp_app_password" = {
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/shared.yaml";
  };

  sops.secrets."ldap_jwt_secret" = {
    owner = "lldap";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };
  sops.secrets."ldap_user_pass" = {
    owner = "lldap";
    sopsFile = "${secretsPath}/secrets/authentication.yaml";
  };

  users = {
    groups.authelia = {};
    users.authelia = {
      isSystemUser = true;
      group = "authelia";
    };
    users.lldap = {
      isSystemUser = true;
      group = "lldap";
    };
    groups.lldap = {};
  };

  # This was super fun to find buried in the service config after two hours debugging.
  systemd.services."authelia-main".serviceConfig.ProtectSystem = lib.mkForce false;

  services.authelia.instances.main = {
    user = "authelia";
    group = "authelia";
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets."authelia_jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia_storage_key".path;
    };

    environmentVariables = {
      AUTHELIA_AUTHENTICATION_BACKEND_LDAP_PASSWORD_FILE = config.sops.secrets."authelia_ldap_password".path;
      AUTHELIA_NOTIFIER_SMTP_PASSWORD_FILE = config.sops.secrets."smtp_app_password".path;
    };
    settings = {
      theme = "dark";

      server = {
        endpoints.authz.forward-auth.implementation = "ForwardAuth";
      };

      session = {
        name = "authelia_session";
        cookies = [
          {
            domain = "${project_tld}";
            authelia_url = "https://auth.${project_tld}";
            default_redirection_url = "https://${project_tld}";
          }
        ];
      };

      authentication_backend.ldap = {
        implementation = "lldap";
        base_dn = base_dn;
        address = "ldap://localhost:3890";
        user = "uid=ldap_admin_authelia,ou=people,${base_dn}";
        attributes = {
          username = "uid";
          mail = "mail";
          display_name = "displayName";
        };
        additional_users_dn = "ou=people";
      };

      # TODO: Move this to an actual db - add full-blown db server?
      storage.local.path = "${config_dir}/db.sqlite3";
      notifier.smtp = {
        address = smtp_address;
        username = "${smtp_sender}";
        sender = "Authelia <${smtp_sender}>";
      };

      identity_validation = {
        reset_password = {
        };
      };

      access_control = {
        default_policy = "deny";
        rules = [
          # Bypass APIs
          {
            domain = [
              "${project_tld}"
              "*.${project_tld}"
            ];
            policy = "bypass";
            resources = [
              "^/api$"
              "^/api/"
            ];
          }
          {
            domain = "auth.${project_tld}";
            policy = "bypass";
          }
          {
            domain = [
              "traefik.${project_tld}"
              "ldap.${project_tld}"
            ];
            subject = "group:admin";
            policy = "one_factor";
          }
          {
            domain = [
              "sonarr.${project_tld}"
              "radarr.${project_tld}"
              "prowlarr.${project_tld}"
              "lidarr.${project_tld}"
              "torrent.${project_tld}"
            ];
            subject = [
              "group:media_admin"
              "group:admin"
            ];
            policy = "one_factor";
          }
          {
            domain = [
              "jellyseer.${project_tld}"
              # TODO
              # "media.${project_tld}"
            ];
            subject = [
              "group:media"
            ];
            policy = "one_factor";
          }
          {
            domain = [
              "recipes.${project_tld}"
              "${project_tld}"
            ];
            policy = "one_factor";
          }
        ];
      };
    };
  };

  services.lldap = {
    enable = true;
    settings = {
      ldap_base_dn = base_dn;
      ldap_user_dn = "ldap_admin";
      ldap_user_email = "ldap_admin@${project_tld}";
      http_url = "https://ldap.${project_tld}";
      database_url = "sqlite://./users.db?mode=rwc";
    };
    environment = {
      LLDAP_JWT_SECRET_FILE = config.sops.secrets."ldap_jwt_secret".path;
      LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."ldap_user_pass".path;
    };
  };

  systemd.services."authelia-main".after = ["lldap.service"];
}
