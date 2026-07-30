{
  pkgs,
  inputs,
  config,
  lib,
  private,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";
  base_dn = "${private.ldap_base_dn}";
  smtp_sender = "${private.smtp_sender}";
  smtp_address = "smtp://${private.smtp_address}:587";

  project_dir = "/services";
  authelia_dir = "${project_dir}/authelia";

  ldap_dir = "${project_dir}/lldap";
  authelia_config_dir = "${authelia_dir}/config";
  authelia_data_dir = "${authelia_dir}/data";
in {
  config = lib.mkMerge [
    {
      CertifiKate.roles.server.routes = {
        authelia = {
          host = "auth";
          dest = "http://auth-01.srv:9091";
          rules = [
            {
              policy = "bypass";
            }
          ];
          dashboard = {
            name = "Authelia";
            description = "Manage logins and access";
            icon = "sh-authelia";
            group = "Settings";
          };
        };
        ldap = {
          host = "ldap";
          dest = "http://auth-01.srv:17170";
          rules = [
            {
              subject = ["group:admin"];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "LLDAP";
            description = "Manage users and groups";
            icon = "sh-lldap";
            group = "Settings";
          };
        };
      };
    }

    (lib.mkIf config.CertifiKate.roles.server.auth.enable {
      # Setup backup service
      CertifiKate.modules.backup_service = {
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
          "d ${authelia_config_dir} 700 authelia authelia"
          "d ${authelia_data_dir} 700 authelia authelia"
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

      # ProtectSystem=strict makes the filesystem read-only except StateDirectory paths.
      # Both services use /services/lldap and /services/authelia which aren't covered,
      # so we disable it for both.
      systemd.services."authelia-main".serviceConfig.ProtectSystem = lib.mkForce false;
      systemd.services."lldap".serviceConfig.ProtectSystem = lib.mkForce false;

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
          storage.local.path = "${authelia_data_dir}/db.sqlite3";
          notifier.smtp = {
            address = smtp_address;
            username = "${smtp_sender}";
            sender = "Authelia <${smtp_sender}>";
          };

          identity_validation = {
            reset_password = {
            };
          };

          access_control = let
            default_rules = [
              {
                domain = "${project_tld}";
                policy = "bypass";
                resources = [
                  "^/api$"
                  "^/api/"
                ];
              }
              {
                domain = "${project_tld}";
                policy = "one_factor";
              }
            ];

            # Transform route rules by injecting domain field
            # For each route, add domain = "${host}.${project_tld}" to each rule
            # But preserve any explicit domain field if already present
            transformedRules = lib.flatten (lib.attrValues (
              lib.mapAttrs (
                name: cfg:
                  if cfg.rules == []
                  then []
                  else
                    map (
                      rule:
                        if rule ? domain
                        then rule # Keep the explicit domain set in the rule!
                        else
                          rule
                          // {
                            domain = "${
                              if cfg.host == ""
                              then ""
                              else "${cfg.host}."
                            }${project_tld}";
                          }
                    )
                    cfg.rules
              )
              config.CertifiKate.roles.server.routes
            ));
          in {
            default_policy = "deny";
            rules = default_rules ++ transformedRules;
          };
        };
      };

      services.lldap = {
        enable = true;
        # I don't want this in config at this stage
        silenceForceUserPassResetWarning = true;
        settings = {
          ldap_base_dn = base_dn;
          ldap_user_dn = "ldap_admin";
          ldap_user_email = "ldap_admin@${project_tld}";
          http_url = "https://ldap.${project_tld}";
          database_url = "sqlite://${ldap_dir}/users.db?mode=rwc";
        };
        environment = {
          LLDAP_JWT_SECRET_FILE = config.sops.secrets."ldap_jwt_secret".path;
          LLDAP_LDAP_USER_PASS_FILE = config.sops.secrets."ldap_user_pass".path;
        };
      };
      # Override the service to use our state dir and disable DynamicUser so the
      # static lldap user (defined above) owns the files consistently across restarts
      systemd.services."lldap".serviceConfig.WorkingDirectory = lib.mkForce "${ldap_dir}";
      systemd.services."lldap".serviceConfig.DynamicUser = lib.mkForce false;

      systemd.services."authelia-main".after = ["lldap.service"];
    })
  ];
}
