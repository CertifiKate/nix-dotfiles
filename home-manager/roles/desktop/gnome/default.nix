let
  wallpaper = "monet.jpg";
in {
  imports = [
    ../common
  ];

  # Setup wallpaper
  home.file.".config/bg/${wallpaper}" = {
    source = ../common/wallpapers/${wallpaper};
  };

  # Reference https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/
  dconf.settings = {
    "org/gnome/shell" = {
      favorite-apps = [
        "firefox.desktop"
        "code.desktop"
        "org.gnome.Console.desktop"
        "org.gnome.Nautilus.desktop"
        # "spotify.desktop"
      ];
    };

    "org/gnome/desktop/interface" = {
      color-scheme = "prefer-dark";
    };
    "org/gnome/desktop/background" = {
      picture-uri = "file:///home/kate/.config/bg/${wallpaper}";
      picture-uri-dark = "file:///home/kate/.config/bg/${wallpaper}";
    };
  };
}
