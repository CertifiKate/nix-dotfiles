{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.media-02 = {
    deployment.tags = ["srv" "media"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/media-dl"
        nixos."roles/server/services/library"
      ];

      networking.hostName = "media-02";
    };
  };
}
