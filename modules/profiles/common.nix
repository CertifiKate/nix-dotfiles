#
# Profile used for every host
# Can use secrets, flake inputs, etc.
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.flake.modules) nixos;
  inherit (config.meta) secretsPath;
in {
  flake.modules.nixos."modules/profiles/common" = {pkgs, ...}: {
    imports = [
      nixos."modules/profiles/base"
      inputs.sops-nix.nixosModules.sops
      nixos."modules/users/kate"
      nixos."modules/nix/remote-build"
      nixos."modules/shell/zsh"
    ];

    nix.settings.experimental-features = ["nix-command" "flakes"];

    # ==============================
    # Shared Sops configuration
    # ==============================
    sops = {
      defaultSopsFile = "${secretsPath}/secrets/shared.yaml";

      # Don't use SSH keys
      age.sshKeyPaths = [];
      gnupg.sshKeyPaths = [];

      age = {
        keyFile = "/etc/sops-age.txt";
        generateKey = false;
      };
    };
    # ==============================

    environment.systemPackages = with pkgs; [
      ranger
      btop
      dig
      tree
      traceroute
      gnumake
    ];

    # Keep SSH agent in sudo
    security.sudo = {
      extraConfig = ''
        Defaults env_keep+=SSH_AUTH_SOCK
        Defaults timestamp_timeout=30
      '';
    };
  };
}
