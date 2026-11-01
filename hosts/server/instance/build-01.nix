{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.build-01 = {
    deployment.tags = ["srv" "build"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/nix-builder"
      ];

      networking.hostName = "build-01";
    };
  };
}
