{
  config,
  lib,
  pkgs,
  ...
}: let
  promUid = "prometheus-incus";
in {
  # Drop the dashboard JSON into /etc where Grafana can read it directly.
  # This sidesteps the Grafana v12 provider-YAML generation bug and the
  # permitted_provisioning_paths allowlist entirely.
  environment.etc."grafana-dashboards/incus-cluster.json".source = ./incus-cluster.json;

  services.grafana.provision = {
    enable = true;

    datasources.settings = {
      apiVersion = 1;
      datasources = [
        {
          name = "Prometheus (Incus)";
          uid = promUid;
          type = "prometheus";
          access = "proxy";
          url = "http://localhost:${toString config.services.prometheus.port}";
          isDefault = true;
          basicAuth = true;
          basicAuthUser = "alloy";
          jsonData = {
            httpMethod = "POST";
            timeInterval = "15s";
          };
          secureJsonData = {
            basicAuthPassword = "$__file{/etc/grafana/prometheus-password}";
          };
        }
      ];
      deleteDatasources = [];
    };

    dashboards.settings = {
      apiVersion = 1;
      providers = [
        {
          name = "incus";
          orgId = 1;
          type = "file";
          disableDeletion = false;
          updateIntervalSeconds = 30;
          allowUiUpdates = true;
          options.path = "/etc/grafana-dashboards";
        }
      ];
    };
  };
}
