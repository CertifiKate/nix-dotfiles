{
  config,
  lib,
  pkgs,
  inputs,
  ...
}: let
  cfg = config.CertifiKate.roles.server.metrics_relay;
  secretsPath = toString inputs.nix-secrets;

  # The stat container's eth1 is on net-infra; the host bridge gateway is 10.10.0.254
  incusHostAddr = "10.10.0.254";
  incusMetricsPort = 8444;

  alloyConfig = pkgs.writeText "alloy.river" ''
    prometheus.scrape "incus" {
      targets = [{"__address__" = "${incusHostAddr}:${toString incusMetricsPort}"}]
      metrics_path    = "/1.0/metrics"
      scheme          = "https"
      scrape_interval = "15s"

      tls_config {
        cert_file            = "/etc/alloy/tls/metrics.crt"
        key_file             = "/etc/alloy/tls/metrics.key"
        insecure_skip_verify = true
      }

      forward_to = [prometheus.relabel.label_server.receiver]
    }

    prometheus.relabel "label_server" {
      rule {
        target_label = "server_name"
        replacement  = "${cfg.incusNode}"
      }
      forward_to = [prometheus.remote_write.monitor.receiver]
    }

    prometheus.remote_write "monitor" {
      endpoint {
        url = "http://monitor-01.srv:9090/api/v1/write"

        basic_auth {
          username      = "alloy"
          password_file = "/etc/alloy/push_password"
        }
      }
    }
  '';
in {
  config = lib.mkIf cfg.enable {
    users.users.alloy = lib.mkDefault {
      isSystemUser = true;
      group = "alloy";
    };
    users.groups.alloy = lib.mkDefault {};

    systemd.tmpfiles.rules = [
      "d /etc/alloy/tls 0750 alloy alloy -"
    ];

    sops.secrets."incus_metrics_crt" = {
      sopsFile = "${secretsPath}/secrets/monitoring.yaml";
      path = "/etc/alloy/tls/metrics.crt";
      owner = "alloy";
    };
    sops.secrets."incus_metrics_key" = {
      sopsFile = "${secretsPath}/secrets/monitoring.yaml";
      path = "/etc/alloy/tls/metrics.key";
      owner = "alloy";
    };
    sops.secrets."alloy_push_password" = {
      sopsFile = "${secretsPath}/secrets/monitoring.yaml";
      path = "/etc/alloy/push_password";
      owner = "alloy";
    };

    services.alloy = {
      enable = true;
      configPath = alloyConfig;
    };
  };
}
