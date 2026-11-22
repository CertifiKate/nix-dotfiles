pkgs: {
  wallpaper = ../wallpapers/monet.jpg;
  colorScheme = import ./_palettes/monet.nix;
  fonts = import ./_fonts/inter.nix pkgs;
  cursor = import ./_cursors/bibata-ice.nix pkgs;
  icons = import ./_icons/papirus-nordic.nix pkgs;
}
