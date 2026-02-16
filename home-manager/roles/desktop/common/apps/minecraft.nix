{pkgs, ...}: {
  home.packages = with pkgs; [
    (prismlauncher.override {
      jdks = [
        temurin-bin-17
      ];
    })
  ];
}
