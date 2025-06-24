{
  pkgs,
  inputs,
  vars,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  home = {
    username = "${vars.user}";
    homeDirectory = "/home/${vars.user}";
  };

  sops = {
    defaultSopsFile = "${secretsPath}/secrets/home-manager.yaml";

    age = {
      keyFile = "/home/${vars.user}/.config/sops-age.txt";
      generateKey = false;
    };
  };

  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    devenv
    lazygit
    ranger
  ];

  programs.zsh = {
    enable = true;
    history.append = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    syntaxHighlighting.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "bira";
      plugins = [
        "direnv"
        "sudo"
      ];
    };
  };

  home.stateVersion = "24.05";
}
