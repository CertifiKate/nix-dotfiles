{config, ...}: {
  programs.alacritty = {
    enable = true;

    settings = {
      window = {
        padding = {
          x = 20;
          y = 20;
        };
        opacity = 0.85;
      };
      colors = {
        primary = {
          foreground = "#${config.colorScheme.palette.base04}";
          background = "#${config.colorScheme.palette.base00}";
        };
      };
    };
  };
}
