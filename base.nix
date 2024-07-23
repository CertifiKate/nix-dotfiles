{ inputs, config, pkgs, ... }:

let 
  secretsPath = builtins.toString inputs.nix-secrets;

  timezone = "Australia/Adelaide";

in {

  imports = [
    ./users/kate.nix
    ./modules/zsh
  ];

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

  # ==============================
  # General System Config
  # ==============================
  time.timeZone = timezone;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    ranger
    btop
    git
  ];

  users = {
    mutableUsers = false;
  };

  # Keep SSH agent in sudo
  security.sudo = {
    extraConfig = ''
    Defaults env_keep+=SSH_AUTH_SOCK
    Defaults timestamp_timeout=30
    '';
  };
  
  # Auto clean old store files
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # ==============================

  # If we change this things will be sad
  system.stateVersion = "23.11";
}