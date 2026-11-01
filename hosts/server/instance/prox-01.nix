{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.prox-01 = {
    deployment.tags = ["srv" "core" "proxy"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/proxy"
        nixos."roles/server/services/cloudflared"
      ];

      networking.hostName = "prox-01";
    };
  };
}
