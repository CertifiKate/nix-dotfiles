{
  config,
  pkgs,
  ...
}: {
  config.virtualisation.oci-containers.containers = {
    actualbudget = {
      autoStart = true;
      image = "ghcr.io/actualbudget/actual-server";
      ports = ["5006:5006"];
      volumes = [
        "/config/actualbudget:/data"
      ];
    };
  };
}
