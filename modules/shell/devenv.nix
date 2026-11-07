{
  flake.modules.homeManager."modules/shell/devenv" = {
    lib,
    pkgs,
    ...
  }: {
    home.packages = [pkgs.devenv];
    programs.zsh.initContent = ''eval "$(${lib.getExe pkgs.devenv} hook zsh)"'';
  };
}
