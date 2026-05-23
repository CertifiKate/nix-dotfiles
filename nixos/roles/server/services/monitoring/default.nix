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
  config =
    {
      imports = [
        "grafana-provisioning.nix"
      ];

      CertifiKate.roles.server.routes = {
        monitor = {
          host = "monitor";
          dest = "http://monitor-01.srv:3000";
          rules = [
            {
              subject = [
                "group:admin"
                "group:monitoring"
              ];
              policy = "one_factor";
            }
          ];
        };
      };
    }
    // lib.mkIf config.CertifiKate.roles.server.monitoring.enable {
      systemd.tmpfiles.rules = [
        "d /etc/prometheus/tls 0750 prometheus prometheus -"
      ];
      # Add in keys for Prometheus to talk to Incus hosts
      sops.secrets."incus_metrics_crt" = {
        sopsFile = "${secretsPath}/secrets/monitoring.yaml";
        path = "/etc/prometheus/tls/metrics.crt";
        owner = "prometheus";
      };
      sops.secrets."incus_metrics_key" = {
        sopsFile = "${secretsPath}/secrets/monitoring.yaml";
        path = "/etc/prometheus/tls/metrics.key";
        owner = "prometheus";
      };
      sops.secrets."incus_metrics_server_cert" = {
        sopsFile = "${secretsPath}/secrets/monitoring.yaml";
        path = "/etc/prometheus/tls/server.crt";
        owner = "prometheus";
      };
      sops.secrets."grafana_secret_key" = {
        sopsFile = "${secretsPath}/secrets/monitoring.yaml";
        path = "/etc/grafana/secret.key";
        owner = "grafana";
      };

      # Grafana
      # Actual dashboards/alerts/etc. are handled in grafana-provisioning.nix
      services.grafana = {
        enable = true;
        openFirewall = true;
        settings = {
          server = {
            http_addr = "0.0.0.0";
            http_port = 3000;
            enforce_domain = true;
            enable_gzip = true;
            domain = "monitoring.${project_tld}";
          };
          security = {
            secret_key = "$__file{${config.sops.secrets."grafana_secret_key".path}}";
          };
          analytics.reporting_enabled = false;
        };
      };

      # Prometheus
      services.prometheus = {
        enable = true;
        checkConfig = "syntax-only";
        scrapeConfigs = [
          {
            job_name = "incus";
            metrics_path = "/1.0/metrics";
            scheme = "https";
            static_configs = [
              {
                # TODO: do for all hosts - make this a bit nicer (move out to options?)
                targets = [
                  "incus-01.infra:8444"
                  "incus-02.infra:8444"
                ];
              }
            ];
            tls_config = {
              ca_file = "/etc/prometheus/tls/server.crt";
              cert_file = "/etc/prometheus/tls/metrics.crt";
              key_file = "/etc/prometheus/tls/metrics.key";
            };
          }
        ];
      };
    };
}
