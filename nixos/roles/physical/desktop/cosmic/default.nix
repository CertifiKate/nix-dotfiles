{pkgs, ...}: {
  imports = [
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  services.displayManager.gdm.enable = true;

  services.desktopManager.cosmic = {
    enable = true;
  };
}
