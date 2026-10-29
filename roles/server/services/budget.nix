{
  homelab.routes.actual = {
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

  flake.modules.nixos."roles/server/services/budget" = let
    actual_budget_dir = "/services/actualbudget";
  in {
    # Setup backup service
    CertifiKate.backup = {
      paths = [
        "${actual_budget_dir}"
      ];
    };

    virtualisation.oci-containers.containers = {
      actualbudget = {
        autoStart = true;
        image = "ghcr.io/actualbudget/actual-server:26.10.0";
        ports = ["5006:5006"];
        volumes = [
          "${actual_budget_dir}:/data"
        ];
      };
    };
  };
}
