{pkgs, ...}: let
in {
  # Add Dir Env and DevEnv
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

  # Enable ZSH configuration for more specific configs (i.e adding aliases for roles)
  # (this /seems/ to be able to run alongside the NixOS config without issue)
  programs.zsh = {
    enable = true;
    enableCompletion = true;
    autosuggestion.enable = true;
    oh-my-zsh = {
      enable = true;
      theme = "bira";
      plugins = [
        "direnv"
        "sudo"
      ];
    };
  };
}
