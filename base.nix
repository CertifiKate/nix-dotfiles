{ inputs, config, pkgs, ... }:

let 
  secretsPath = builtins.toString inputs.nix-secrets;
in {

  imports = [
    ./users/kate.nix
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
  sops.secrets."project_tld" = {};

  # Read only key for secrets repo - means we don't need the yubikey except for initial setup or if something goes wrong
  sops.secrets."sops_secrets_ssh_private_key" = {
    path = "/etc/ssh/ssh_git_secrets_key";
  };
  # ==============================

  time.timeZone = "Australia/Adelaide";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    # TODO: Move to end-device role
    sops
    age

    ranger
    zsh
    oh-my-zsh
    btop
    git

    # Is it neccessary to install this just for a nicer MOTD? .. Yes
    figlet
  ];



  system.userActivationScripts.zshrc = "touch .zshrc";

  environment.etc = {
    "bulbhead.flf".source = ./lib/bulbhead.flf;
  };

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };

    promptInit = ''
      echo "$fg[red]$(figlet $(cat /etc/hostname) -f /etc/bulbhead.flf)"
      # TODO: Work out why this isn't being properly set in ZSH
      export HOST=$(cat /etc/hostname)
    '';
  };

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
  };

  # Keep SSH agent in sudo
  security.sudo = {
    extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";
  };



  # If we change this things will be sad
  system.stateVersion = "23.11";
}