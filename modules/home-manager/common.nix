{config, ...}: let
  inherit (config.meta) secretsPath user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager."modules/home-manager/common" = {
    imports = [
      homeManager."modules/home-manager/base"
      homeManager."modules/nix/remote-build"
    ];

    sops = {
      defaultSopsFile = "${secretsPath}/secrets/home-manager.yaml";

      age = {
        keyFile = "/home/${user}/.config/sops-age.txt";
        generateKey = false;
      };
    };
  };
}
