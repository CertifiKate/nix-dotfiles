{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.nixos."roles/physical/desktop/gnome" = {pkgs, ...}: {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # Enable the GNOME Desktop Environment.
    services.displayManager.gdm.enable = true;
    services.desktopManager.gnome.enable = true;

    # Remove unwanted packages
    environment.gnome.excludePackages = with pkgs; [
      baobab # disk usage analyzer
      cheese # photo booth
      eog # image viewer
      epiphany # web browser
      gedit # text editor
      totem # video player
      yelp # help viewer
      evince # document viewer
      geary # email client
      gnome-tour
      gnome-calendar
      gnome-connections
      gnome-characters
      gnome-clocks
      gnome-contacts
      gnome-logs
      gnome-maps
      gnome-music
      gnome-weather
    ];

    home-manager.users.${user}.imports = [homeManager."roles/physical/desktop/gnome"];
  };

  flake.modules.homeManager."roles/physical/desktop/gnome" = let
    wallpaper = "monet.jpg";
  in {
    imports = [
      homeManager."roles/physical/desktop"
    ];

    # Setup wallpaper
    home.file.".config/bg/${wallpaper}" = {
      source = ./wallpapers/${wallpaper};
    };

    # Reference https://hoverbear.org/blog/declarative-gnome-configuration-in-nixos/
    dconf.settings = {
      "org/gnome/shell" = {
        favorite-apps = [
          "firefox.desktop"
          "code.desktop"
          "org.gnome.Console.desktop"
          "org.gnome.Nautilus.desktop"
          "spotify.desktop"
        ];
      };

      # Visual settings
      "org/gnome/desktop/interface" = {
        color-scheme = "prefer-dark";
        clock-format = "12h";
      };
      "org/gtk/settings/file-chooser" = {
        clock-format = "12h";
      };
      "org/gnome/desktop/background" = {
        picture-uri = "file:///home/${user}/.config/bg/${wallpaper}";
        picture-uri-dark = "file:///home/${user}/.config/bg/${wallpaper}";
      };

      # Keyboard shortcuts
      "org/gnome/desktop/wm/keybindings" = {
        switch-to-workspace-1 = ["<Super>1"];
        switch-to-workspace-2 = ["<Super>2"];
        switch-to-workspace-3 = ["<Super>3"];
        switch-to-workspace-4 = ["<Super>4"];
        move-to-workspace-1 = ["<Shift><Super>1"];
        move-to-workspace-2 = ["<Shift><Super>2"];
        move-to-workspace-3 = ["<Shift><Super>3"];
        move-to-workspace-4 = ["<Shift><Super>4"];
        toggle-maximized = ["<Super>f"];
        switch-windows = ["<Alt>Tab"];
        close = ["<Super>q"];
      };

      # TODO: Solve this
      # 'Custom' shortcuts
      # "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings" = {
      #   custom0 = {
      #     name = "Launch Terminal";
      #     binding = ["<Super>Return"];
      #     command = "kgx";
      #   };
      # };
    };
  };
}
