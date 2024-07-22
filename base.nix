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
  # ==============================

  time.timeZone = "Australia/Adelaide";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
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

  # TODO: Split this into it's own module with custom theming based on host vars (ie. change hostname prompt colour based on if end-device or server)
  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    syntaxHighlighting.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };
    shellAliases = {
      nr = "nixos-rebuild switch --flake /etc/nixos/flake.nix ";
    };

    # TODO: Cache the figlet -f to a motd file
    promptInit = ''
      # Nix remote rebuild
      nrr() {
        nixos-rebuild --target-host $USER@$1 --use-remote-sudo switch --flake .
      }

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

  # TODO: Find a way to add this into users/kate.nix without breaking golden image
  sops.secrets."users_kate_password_hash".neededForUsers = true;
  users.users.kate = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets."users_kate_password_hash".path;
  };

  # TODO: Add auto garbage-collect

  nix.settings.trusted-users = [
    "ansible"
    # "kate"
  ];

  # If we change this things will be sad
  system.stateVersion = "23.11";
}