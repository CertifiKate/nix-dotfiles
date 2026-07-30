{
  config,
  lib,
  ...
}: let
  actual_budget_dir = "/services/actualbudget";
in {
  config = lib.mkMerge [
    {
      CertifiKate.roles.server.routes.actual = {
        host = "actualbudget";
        dest = "http://util-01.srv:5006";
        rules = [
          {
            policy = "bypass";
          }
        ];
        dashboard = {
          name = "Actual Budget";
          description = "Personal finance and budgeting";
          icon = "sh-actual-budget";
          group = "Finance";
        };
      };
    }

    # Service configuration - only when budget service is enabled
    (lib.mkIf config.CertifiKate.roles.server.budget.enable {
      # Setup backup service
      CertifiKate.modules.backup_service = {
        paths = [
          "${actual_budget_dir}"
        ];
      };

      virtualisation.oci-containers.containers = {
        actualbudget = {
          autoStart = true;
          image = "ghcr.io/actualbudget/actual-server:26.7.0";
          ports = ["5006:5006"];
          volumes = [
            "${actual_budget_dir}:/data"
          ];
        };
      };
    })
  ];
}
