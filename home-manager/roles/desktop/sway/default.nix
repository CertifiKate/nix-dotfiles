{
  pkgs,
  inputs,
  nix-colors,
  ...
}: let
  wallpaper = "monet.jpg";
in {
  imports = [
    nix-colors.homeManagerModules.default
    ../common/apps
    # ./colours
    ./waybar.nix
    ./wofi.nix
  ];

  # Setup wallpaper
  home.file.".config/bg/${wallpaper}" = {
    source = ../common/wallpapers/${wallpaper};
  };

  home.packages = with pkgs; [
    swaybg
  ];

  # Setup our nix-colors scheme
  colorScheme = nix-colors.colorSchemes.da-one-paper;

  wayland.windowManager.sway = {
    enable = true;
    config = let
      workspaces = {
        ws1 = "1";
        ws2 = "2";
        ws3 = "3";
        ws4 = "4";
        ws5 = "5";
        ws6 = "6";
        ws7 = "7";
        ws8 = "8";
        ws9 = "9";
        ws10 = "10";
      };
      mod = "Mod4";
    in {
      defaultWorkspace = "workspace ${workspaces.ws1}";
      gaps = {
        inner = 10;
        outer = 20;
      };
      startup = [{command = "${pkgs.swaybg}/bin/swaybg -i ~/.config/bg/${wallpaper}";}];
      bars = [
        {
          command = "${pkgs.waybar}/bin/waybar";
        }
      ];
      window = {
        titlebar = false;
      };
      keybindings = import ./bindings.nix {inherit pkgs mod workspaces;};
    };
  };
}
