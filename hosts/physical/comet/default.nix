# === GPD Pocket 3 ===
{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) nixos homeManager;

  squareTheme = {
    # Just enough to separate windows, as flush tiling looks unfinished
    gaps = "(2, 2)";
    active_hint = "1";
    is_frosted = "true";
    corner_radii = ''
      (
          radius_0: (0.0, 0.0, 0.0, 0.0),
          radius_xs: (0.0, 0.0, 0.0, 0.0),
          radius_s: (0.0, 0.0, 0.0, 0.0),
          radius_m: (0.0, 0.0, 0.0, 0.0),
          radius_l: (0.0, 0.0, 0.0, 0.0),
          radius_xl: (0.0, 0.0, 0.0, 0.0),
      )
    '';
  };
in {
  configurations.nixos.comet.module = {
    imports = [
      ./_hardware-configuration.nix
      nixos."modules/profiles/physical"
      nixos."roles/physical/common/impermanence"

      nixos."roles/physical/desktop/cosmic"
      nixos."modules/network/wireguard"
    ];

    CertifiKate.wireguard.interfaces = ["Home"];

    home-manager.users.${user} = {
      imports = [
        homeManager."modules/personal"
        homeManager."modules/personal/ssh-client"
      ];

      CertifiKate.cosmic = {
        powerKeyDialog = false;
        # The touchpad firmware sends Windows shortcuts for three-finger swipes: Alt+(Shift+)Tab then held
        # arrows for left/right (window switcher, left as is), Super+d for down (already the launcher), and
        # Super+Tab for up - a second window switcher, so that one opens the overview instead
        shortcuts = [
          {
            modifiers = ["Super"];
            key = "Tab";
            action = "System(WorkspaceOverview)";
            description = "Workspace overview (three-finger swipe up)";
          }
        ];
        outputs."DSI-1" = {
          width = 1200;
          height = 1920;
          scale = 1.5;
          autoRotate = true;
        };
        settings = {
          # 8" screen: square, near-gapless and a solid flush bar, as the floating look costs space for nothing here
          "com.system76.CosmicTheme.Dark" = squareTheme;
          "com.system76.CosmicTheme.Dark.Builder" = squareTheme;
          "com.system76.CosmicPanel.Panel" = {
            # Matches the window gaps
            margin = "2";
            anchor_gap = "true";
            # Smaller than XS, as the 8px padding makes up the rest - 44px overall
            size = "Custom(28)";
            border_radius = "8";
            spacing = "2";
            opacity = "1.0";
          };
          # Room for the date on the centred clock, which saves opening the calendar to check it
          "com.system76.CosmicAppletTime" = {
            show_date_in_top_panel = "true";
            show_weekday = "true";
          };
          "com.system76.CosmicIdle" = {
            screen_off_time = "Some(300000)";
            suspend_on_battery_time = "Some(600000)";
          };
          # Idle suspend runs the Suspend action, so match the lid and power key's hibernate fallback
          "com.system76.CosmicSettings.Shortcuts".system_actions = ''{Suspend: "systemctl suspend-then-hibernate"}'';
        };
      };
    };
    networking.hostName = "comet";
  };
}
