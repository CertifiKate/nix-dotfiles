#
# Secret-free home-manager config shared by every machine
# Must not reference nix-secrets/sops so it can be used on untrusted (ie. work) devices
#
{
  pkgs,
  vars,
  ...
}: {
  home = {
    username = "${vars.user}";
    homeDirectory = "/home/${vars.user}";
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
    nix-tree
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
