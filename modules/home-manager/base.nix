#
# Secret-free home-manager config shared by every machine
# Must not reference nix-secrets/sops so it can be used on untrusted (ie. work) devices
#
{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager."modules/home-manager/base" = {pkgs, ...}: {
    imports = [
      homeManager."modules/shell/devenv"
      homeManager."modules/shell/zsh"
    ];

    home = {
      username = "${user}";
      homeDirectory = "/home/${user}";
    };

    home.packages = with pkgs; [
      lazygit
      ranger
      nix-tree
      btop
      dig
      tree
      traceroute
      gnumake
    ];

    home.stateVersion = "24.05";
  };
}
