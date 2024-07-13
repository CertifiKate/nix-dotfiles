{ config, lib, pkgs, modulesPath, ... }:

let 
  project_tld = "";

in {
  time.timeZone = "Australia/Adelaide";


  environment.systemPackages = with pkgs; [
    python3
    ranger
    zsh
    oh-my-zsh
    btop

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
  };

  # Enable passwordless sudo.
  security.sudo.extraRules = [
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

  system.userActivationScripts.zshrc = "touch .zshrc";

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };

    promptInit = ''
      echo "$fg[red]$(figlet ${config.networking.hostname} -f /etc/nixos/lib/figlet-font.flf)"
      # TODO: Work out why this isn't being properly set in ZSH
      export HOST=${config.networking.hostname}
    '';
  };

  # TODO: Make this only on specific machines - used for VS Code Remote SSH
  programs.nix-ld.enable = true;

  services.openssh.enable = true;

  system.stateVersion = "23.11";
}