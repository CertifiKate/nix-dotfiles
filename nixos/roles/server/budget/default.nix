{
  config,
  pkgs,
  ...
}: let
  actual_budget_dir = "/services/actualbudget";
in {
  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${actual_budget_dir}"
    ];
  };

  virtualisation.oci-containers.containers = {
    actualbudget = {
      autoStart = true;
      image = "ghcr.io/actualbudget/actual-server:25.7.1";
      ports = ["5006:5006"];
      volumes = [
        "${actual_budget_dir}:/data"
      ];
    };
  };
}
