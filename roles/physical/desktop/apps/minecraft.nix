{
  flake.modules.homeManager."roles/physical/desktop/apps" = {pkgs, ...}: {
    home.packages = with pkgs; [
      (prismlauncher.override {
        jdks = [
          temurin-bin-17
        ];
      })
    ];
  };
}
