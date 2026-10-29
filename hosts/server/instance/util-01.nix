{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.util-01 = {
    deployment.tags = ["srv" "util"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/services/budget"
      ];

      networking.hostName = "util-01";
    };
  };
}
