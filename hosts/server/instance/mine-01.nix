{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  # Not deployed with colmena yet - add `deployment.tags = ["srv" "minecraft"];` to enable
  configurations.nixos.mine-01 = {
    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/vm"
        nixos."roles/server/services/minecraft"
      ];

      networking.hostName = "mine-01";
    };
  };
}
