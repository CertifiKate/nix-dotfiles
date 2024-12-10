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
    PROMPT_COLOR = "red";
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

    promptInit = ''
      # Nix remote rebuild
      nrr() {
        nixos-rebuild --target-host ${remote_rebuild_user}@$1 --use-remote-sudo switch --flake $NIX_FLAKE_PATH
      }

      if ! [ -e "~/.motd" ] ; then
        sh -c 'figlet $(cat /etc/hostname) -lf /etc/bulbhead.flf > ~/.motd'
      fi

      echo "$fg[$PROMPT_COLOR]$(cat ~/.motd)"
    '';
  };

  # Set this as default shell. What other user is going to complain? It's just me
  users.defaultUserShell = pkgs.zsh;
}
