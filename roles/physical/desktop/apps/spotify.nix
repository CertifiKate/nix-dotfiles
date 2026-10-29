{
  flake.modules.homeManager."roles/physical/desktop/apps" = {pkgs, ...}: {
    home.packages = with pkgs; [
      spotify
    ];
  };
}
