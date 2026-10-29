{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.mgmt-01 = {
    deployment.tags = ["srv" "mgmt"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/vm"
        nixos."roles/server/services/remote-desktop"
        nixos."modules/home-manager"
      ];

      networking.hostName = "mgmt-01";
    };
  };
}
