{pkgs, ...}: let
in {
  imports = [
    ./ssh-client
  ];

  # Configure our git config
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };

  # Add Dir Env and DevEnv
  programs.direnv = {
    enable = true;
    enableZshIntegration = true;
    nix-direnv.enable = true;
  };

  home.packages = with pkgs; [
    devenv
    lazygit
  ];

  # Enable ZSH configuration for more specific configs (i.e adding aliases for roles)
  # (this /seems/ to be able to run alongside the NixOS config without issue)
  programs.zsh = {
    enable = true;
    oh-my-zsh = {
      plugins = [
        "direnv"
      ];
    };
  };
}
