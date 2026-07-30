{
  lib,
  config,
  inputs,
  private,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
  project_tld = "${private.project_tld}";
in {
  # imports must live at the module top level, not inside config = { }
  imports = [
    ./grafana-provisioning.nix
  ];

  config = lib.mkMerge [
    {
      CertifiKate.roles.server.routes.monitor = {
        host = "monitoring";
        dest = "http://monitor-01.srv:3000";
        rules = [
          {
            subject = ["group:admin" "group:monitoring"];
            policy = "one_factor";
          }
        ];
        dashboard = {
          name = "Grafana";
          description = "Infrastructure monitoring and dashboards";
          icon = "sh-grafana";
          group = "Settings";
        };
      };
    }

    (
      lib.mkIf config.CertifiKate.roles.server.monitoring.enable {
        systemd.tmpfiles.rules = [
          "d /etc/prometheus/tls 0750 prometheus prometheus -"
        ];

        sops.secrets."grafana_secret_key" = {
          sopsFile = "${secretsPath}/secrets/monitoring.yaml";
          path = "/etc/grafana/secret.key";
          owner = "grafana";
        };
        sops.secrets."alloy_push_password_hash" = {
          sopsFile = "${secretsPath}/secrets/monitoring.yaml";
          owner = "prometheus";
        };
        sops.secrets."alloy_push_password" = {
          sopsFile = "${secretsPath}/secrets/monitoring.yaml";
          path = "/etc/grafana/prometheus-password";
          owner = "grafana";
        };

        sops.templates."prometheus-web-config" = {
          content = ''
            basic_auth_users:
              alloy: ${config.sops.placeholder."alloy_push_password_hash"}
          '';
          path = "/etc/prometheus/web-config.yaml";
          owner = "prometheus";
        };

        services.grafana = {
          enable = true;
          openFirewall = true;
          settings = {
            server = {
              http_addr = "0.0.0.0";
              http_port = 3000;
              enforce_domain = false;
              enable_gzip = true;
              domain = "monitoring.${project_tld}";
            };
            security.secret_key = "$__file{${config.sops.secrets."grafana_secret_key".path}}";
            analytics.reporting_enabled = false;
            "feature_toggles".kubernetesDashboards = false;
          };
        };

        networking.firewall.interfaces."eth0".allowedTCPPorts = [9090];

        services.prometheus = {
          enable = true;
          port = 9090;
          checkConfig = "syntax-only";

          extraFlags = [
            "--web.enable-remote-write-receiver"
            "--web.config.file=${config.sops.templates."prometheus-web-config".path}"
          ];

          globalConfig = {
            scrape_interval = "15s";
            evaluation_interval = "15s";
          };

          scrapeConfigs = [
          ];
        };
      }
    )
  ];
}
