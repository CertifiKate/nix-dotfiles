{pkgs, ...}: {
  security.polkit.enable = true;
  services.displayManager.sessionPackages = with pkgs; [sway];
}
