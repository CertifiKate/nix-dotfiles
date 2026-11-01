{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.media-01 = {
    deployment.tags = ["srv" "media"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/jellyfin"
      ];

      networking.hostName = "media-01";
    };
  };
}
