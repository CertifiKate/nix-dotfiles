{
  flake.modules.homeManager."modules/shell/direnv" = {
    programs.direnv = {
      enable = true;
      enableZshIntegration = true;
      nix-direnv.enable = true;
    };
  };
}
