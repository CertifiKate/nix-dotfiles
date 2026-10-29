{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  # Not deployed with colmena yet - add `deployment.tags = ["srv" "core" "backup"];` to enable
  configurations.nixos.backup-01 = {
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
