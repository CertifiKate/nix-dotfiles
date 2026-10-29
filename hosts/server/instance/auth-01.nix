{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.auth-01 = {
    deployment.tags = ["srv" "core" "auth"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/services/auth"
      ];

      networking.hostName = "auth-01";
    };
  };
}
