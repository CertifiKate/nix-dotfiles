{pkgs, ...}:
{

  environment.systemPackages = with pkgs; [
    zsh
    oh-my-zsh
    figlet
  ];

  environment.variables = {
    NIX_FLAKE_PATH = "/etc/nixos/flake.nix";
  };

  system.userActivationScripts.zshrc = "touch .zshrc";

  # Font used for figlet MOTD
  environment.etc = {
    "bulbhead.flf".source = ../../lib/bulbhead.flf;
  };

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
    };

    shellAliases = {
      nr = "sudo nixos-rebuild switch --flake $NIX_FLAKE_PATH";
    };

    # TODO: Cache the figlet -f to a motd file
    promptInit = ''
      # Nix remote rebuild
      nrr() {
        nixos-rebuild --target-host $USER@$1 --use-remote-sudo switch --flake $NIX_FLAKE_PATH
      }

      echo "$fg[red]$(figlet $(cat /etc/hostname) -f /etc/bulbhead.flf)"
      # TODO: Work out why this isn't being properly set in ZSH
      export HOST=$(cat /etc/hostname)
    '';
  };

  # Set this as default shell. What other user is going to complain? It's just me
  users.defaultUserShell = pkgs.zsh;
}