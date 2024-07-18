{ inputs, config, pkgs, ... }:

let 
  secretsPath = builtins.toString inputs.nix-secrets;
in {

  # ==============================
  # Shared Sop configuration
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

  sops.secrets.project_tld = {};

  # Read only key for secrets repo - means we don't need the yubikey except for initial setup or if something goes wrong
  # sops.secrets.sops_secrets_ssh_private_key = {
  #   path = "/etc/ssh/ssh_git_secrets_key";
  # };

  # sops.secrets."ssh_keys.kate.public" = {};
  # ==============================
  
  
  time.timeZone = "Australia/Adelaide";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    # TODO: Move to role
    sops
    age

    # TODO: Move to server role - for ansible
    python3

    ranger
    zsh
    oh-my-zsh
    btop
    git

    # Is it neccessary to install this just for a nicer MOTD? .. Yes
    figlet
  ];

  users = {
    mutableUsers = false;
    defaultUserShell = pkgs.zsh;
    users.ansible = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "";
    };

    users.kate = {
      isNormalUser = true;
      extraGroups = [ "wheel" ];
      hashedPassword = "";
      # openssh.authorizedKeys.keys = sops.
    };
  };

  security.sudo = {
    # Keep SSH agent in sudo
    extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";
    # Enable passwordless sudo for ansible user
    extraRules = [
      {
        users = [ "ansible" ];
        commands = [
          { 
            command = "ALL" ;
            options= [ "NOPASSWD" ];
          }
        ];
      }
    ];
  };

  system.userActivationScripts.zshrc = "touch .zshrc";

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };

    # promptInit = ''
    #   echo "$fg[red]$(figlet ${config.networking.hostname} -f /etc/nixos/lib/figlet-font.flf)"
    #   # TODO: Work out why this isn't being properly set in ZSH
    #   # export HOST=${config.networking.hostname}
    # '';
  };

  services.openssh.enable = true;

  system.stateVersion = "23.11";
  nixpkgs.hostPlatform = "x86_64-linux";
}