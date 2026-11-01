{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.backup-01 = {
    deployment.tags = ["srv" "core" "backup"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/vm"
        nixos."modules/backup/server"
      ];

      networking.hostName = "backup-01";
    };
  };
}
