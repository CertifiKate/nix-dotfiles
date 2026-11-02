{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager."modules/home-manager/common" = {
    imports = [
      homeManager."modules/home-manager/base"
      homeManager."modules/nix/remote-build"
      homeManager."modules/secrets/sops"
    ];
  };
}
