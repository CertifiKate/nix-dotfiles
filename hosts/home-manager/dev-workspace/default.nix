#
# Standalone home-manager for machines this flake doesn't manage, applied by install.sh
# Only for secret-free modules, as most of these machines can't fetch nix-secrets. See ./secrets.nix
#
{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  configurations.home.dev-workspace.module = homeManager."hosts/home-manager/dev-workspace";

  flake.modules.homeManager."hosts/home-manager/dev-workspace" = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      homeManager."modules/home-manager/base"
      homeManager."modules/personal"
    ];

    # Whoever is running it, so that it works for any user. Needs --impure, which install.sh passes
    home = {
      username = lib.mkForce (builtins.getEnv "USER");
      homeDirectory = lib.mkForce (builtins.getEnv "HOME");

      packages = with pkgs; [
        iproute2
        iputils
        wget
      ];
    };

    # The workspace itself knows nothing about Nix, so everything it needs is set up here
    home.sessionPath = ["$HOME/.nix-profile/bin"];
    xdg.configFile."nix/nix.conf".text = ''
      experimental-features = nix-command flakes
      sandbox = false
    '';

    programs.home-manager.enable = true;
    targets.genericLinux = {
      enable = true;
      gpu.enable = false; # Its setup needs root
    };
  };
}
