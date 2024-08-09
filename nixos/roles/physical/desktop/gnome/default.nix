{pkgs, ...}: {
  imports = [
  ];

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the GNOME Desktop Environment.
  services.xserver.displayManager.gdm.enable = true;
  services.xserver.desktopManager.gnome.enable = true;

  # Remove unwanted packages
  environment.gnome.excludePackages = with pkgs; [
    baobab # disk usage analyzer
    cheese # photo booth
    eog # image viewer
    epiphany # web browser
    pkgs.gedit # text editor
    totem # video player
    yelp # help viewer
    evince # document viewer
    geary # email client
    gnome-tour

    gnome-calendar
    gnome-connections
    gnome.gnome-characters
    gnome.gnome-clocks
    gnome.gnome-contacts
    gnome.gnome-logs
    gnome.gnome-maps
    gnome.gnome-music
    gnome.gnome-weather
  ];
}
