{
  inputs,
  config,
  ...
}: let
  inherit (config.flake.modules) homeManager;
  inherit (inputs) nix-colors;
in {
  flake.modules.nixos."roles/physical/desktop/sway" = {pkgs, ...}: {
    security.polkit.enable = true;
    services.displayManager.sessionPackages = with pkgs; [sway];
  };

  flake.modules.homeManager."roles/physical/desktop/sway" = {pkgs, ...}: let
    wallpaper = "monet.jpg";
  in {
    imports = [
      nix-colors.homeManagerModules.default
      homeManager."roles/physical/desktop/apps"
      # ./colours
    ];

    # Setup wallpaper
    home.file.".config/bg/${wallpaper}" = {
      source = ../wallpapers/${wallpaper};
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
        keybindings = import ./_bindings.nix {inherit pkgs mod workspaces;};
      };
    };
  };
}
