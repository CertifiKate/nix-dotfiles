{pkgs, ...}: let
  remote_rebuild_user = "deploy_user";
  remote_build_srv = "build-01.srv";
in {
  environment.systemPackages = with pkgs; [
    zsh
    oh-my-zsh
    figlet
  ];

  environment.variables = {
    NIX_FLAKE_PATH = "/etc/nixos/";
  };

  # Font used for figlet MOTD
  environment.etc = {
    "bulbhead.flf".source = ../../../lib/bulbhead.flf;
  };

  programs.zsh = {
    enable = true;
    enableBashCompletion = true;
    enableCompletion = true;
    autosuggestions.enable = true;
    ohMyZsh = {
      enable = true;
      theme = "bira";
      plugins = [
        "sudo"
      ];
    };

    shellAliases = {
      nr = "sudo nixos-rebuild switch --flake $NIX_FLAKE_PATH";
    };

    # TODO: Cache the figlet -f to a motd file
    # TODO: Split this out
    # TODO: Add better rebuilding - caching to build-01 regardless of options??
    promptInit = ''
      # Nix remote rebuild
      nrr() {
        nixos-rebuild --target-host ${remote_rebuild_user}@$1 --use-remote-sudo switch --flake $NIX_FLAKE_PATH
      }
      # Testing remote rebuild with build host
      nrb(){
        nixos-rebuild --build-host ${remote_rebuild_user}@${remote_build_srv} --target-host ${remote_rebuild_user}@$1 --use-remote-sudo switch --flake $NIX_FLAKE_PATH
      }

      echo "$fg[red]$(figlet $(cat /etc/hostname) -f /etc/bulbhead.flf)"
      # TODO: Work out why this isn't being properly set in ZSH
      export HOST=$(cat /etc/hostname)
    '';
  };

  # Set this as default shell. What other user is going to complain? It's just me
  users.defaultUserShell = pkgs.zsh;
}
