{config, ...}: let
  inherit (config.meta) versions;
in {
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
    CertifiKate.persist.directories = [
      "${actual_budget_dir}"
    ];

    virtualisation.oci-containers.containers = {
      actualbudget = {
        autoStart = true;
        image = "ghcr.io/actualbudget/actual-server:${versions.actualbudget}";
        ports = ["5006:5006"];
        volumes = [
          "${actual_budget_dir}:/data"
        ];
      };
    };
  };
}
