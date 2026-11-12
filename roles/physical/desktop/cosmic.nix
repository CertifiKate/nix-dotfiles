{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.nixos."roles/physical/desktop/cosmic" = {pkgs, ...}: {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    services.displayManager.gdm.enable = true;

    services.desktopManager.cosmic = {
      enable = true;
    };

    # Used by the media key system actions
    environment.systemPackages = [pkgs.playerctl];

    home-manager.users.${user}.imports = [homeManager."roles/physical/desktop/cosmic"];
  };

  flake.modules.homeManager."roles/physical/desktop/cosmic" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.CertifiKate.cosmic;
    wallpaper = "monet.jpg";

    ronList = ids: "[${lib.concatMapStrings (id: "\"${id}\", ") ids}]";

    settings = {
      # === Compositor ===
      # Tile by default, but per-workspace so any workspace can be flipped to floating (Super+t)
      "com.system76.CosmicComp" = {
        autotile = "true";
        autotile_behavior = "PerWorkspace";
        active_hint = "true";
        focus_follows_cursor = "false";
        cursor_follows_focus = "true";
        # System default, but with natural scrolling
        input_touchpad = ''
          (
              state: Enabled,
              click_method: Some(Clickfinger),
              scroll_config: Some((method: Some(TwoFinger), natural_scroll: Some(true), scroll_button: None, scroll_factor: None)),
              tap_config: Some((enabled: true, button_map: Some(LeftRightMiddle), drag: true, drag_lock: false)),
          )
        '';
      };

      "com.system76.CosmicSettings.Shortcuts" = {
        custom = shortcuts [
          # i3
          (bind ["Super"] "Return" "System(Terminal)" "Open terminal")
          (bind ["Super"] "d" "System(Launcher)" "Open launcher")
          (bind ["Super" "Shift"] "q" "Close" "Close window")
          (bind ["Super" "Shift"] "f" "Fullscreen" "Toggle fullscreen")
          (bind ["Super" "Shift"] "space" "ToggleWindowFloating" "Toggle floating")
          (bind ["Super"] "e" "ToggleOrientation" "Toggle split orientation")
          (bind ["Super" "Shift"] "e" "System(LogOut)" "Log out")
          (bind ["Super"] "t" "ToggleTiling" "Toggle tiling on workspace")
          (bind ["Super" "Shift"] "f" "Fullscreen" "Toggle fullscreen")
          (bind ["Super"] "m" "Maximize" "Toggle maximized")
          (bind ["Super" "Shift"] "s" "System(Screenshot)" "Screenshot")
          (bind ["Super"] "space" "System(Launcher)" "Open launcher")
        ];
      };

      # Things that should never tile
      "com.system76.CosmicSettings.WindowRules" = {
        tiling_exception_custom = ''
          [
              (appid: "org.pulseaudio.pavucontrol", title: ".*", enabled: true),
              (appid: ".*blueman-manager.*", title: ".*", enabled: true),
              (appid: "nm-connection-editor", title: ".*", enabled: true),
              (appid: "org.gnome.Calculator", title: ".*", enabled: true),
              (appid: "xdg-desktop-portal-gtk", title: ".*", enabled: true),
              (appid: "firefox", title: "Picture-in-Picture", enabled: true),
              (appid: "Bitwarden", title: ".*", enabled: true),
          ]
        '';
      };

      # === Top bar ===
      # Floating frosted bar: workspaces | clock | tray + quick settings
      # No dock - apps come from the launcher/app library instead
      "com.system76.CosmicPanel" = {
        entries = ''["Panel"]'';
      };
      "com.system76.CosmicPanel.Panel" = {
        name = ''"Panel"'';
        anchor = "Top";
        # Margin matches the outer tiling gap so windows line up with the bar
        anchor_gap = "true";
        expand_to_edges = "true";
        margin = "8";
        border_radius = "12";
        size = "XS";
        opacity = "0.75";
        background = "ThemeDefault";
        exclusive_zone = "true";
        # Stay floating instead of snapping flush when a window is maximised
        keep_style_on_maximize = "true";
        autohide = "Never";
        output = "All";
        plugins_wings = "Some((${ronList cfg.panel.left}, ${ronList cfg.panel.right}))";
        plugins_center = "Some(${ronList cfg.panel.center})";
      };

      "com.system76.CosmicAppletTime" = {
        military_time = "false";
        show_weekday = "false";
        show_date_in_top_panel = "false";
      };
      "com.system76.CosmicAppletBattery" = {
        show_percentage = "true";
      };

      # === Look ===
      # Only the scalar theme values are set here. Colours live in the computed theme, which
      # only the Settings app can rebuild, so pick the accent under Appearance
      "com.system76.CosmicTheme.Mode" = {
        is_dark = "true";
      };
      "com.system76.CosmicTheme.Dark" = themeScalars;
      "com.system76.CosmicTheme.Dark.Builder" = themeScalars;

      "com.system76.CosmicBackground" = {
        same-on-all = "true";
        all = ''
          (
              output: "all",
              source: Path("/home/${user}/.config/bg/${wallpaper}"),
              filter_by_theme: false,
              rotation_frequency: 600,
              filter_method: Lanczos,
              scaling_mode: Zoom,
              sampling_method: Alphanumeric,
          )
        '';
      };
    };

    # Gaps are (outer, inner). Frosted blurs the bar and popovers
    themeScalars = {
      gaps = "(8, 8)";
      active_hint = "2";
      is_frosted = "true";
    };

    bind = modifiers: key: action: description: ''
      (
          modifiers: [${lib.concatStringsSep ", " modifiers}],
          key: "${key}",
          description: Some("${description}"),
      ): ${action},
    '';
    shortcuts = binds: "{\n${lib.concatStrings binds}}";

    writeSettings = lib.concatStrings (lib.flatten (lib.mapAttrsToList (
        component: keys:
          lib.mapAttrsToList (key: value: let
            src = pkgs.writeText "${component}-${key}" value;
            dst = "$HOME/.config/cosmic/${component}/v1/${key}";
          in ''
            if ! cmp -s ${src} "${dst}"; then
              run mkdir -p "$(dirname "${dst}")"
              tmp=$(mktemp -p "$HOME/.config/cosmic")
              run install -m644 ${src} "$tmp"
              run mv "$tmp" "${dst}"
            fi
          '')
          keys
      )
      cfg.settings));

    # Waits for the compositor, as graphical-session.target can be reached before it's taking requests
    applyOutputs = pkgs.writeShellScript "cosmic-outputs" ''
      for _ in $(seq 30); do
        ${pkgs.cosmic-randr}/bin/cosmic-randr list >/dev/null 2>&1 && break
        sleep 1
      done
      ${lib.concatStrings (lib.mapAttrsToList (name: output: ''
          ${pkgs.cosmic-randr}/bin/cosmic-randr mode ${name} ${toString output.width} ${toString output.height} \
            --scale ${lib.strings.floatToString output.scale}
        '')
        cfg.outputs)}
    '';
  in {
    imports = [
      homeManager."roles/physical/desktop"
    ];

    options.CertifiKate.cosmic = {
      settings = lib.mkOption {
        type = with lib.types; attrsOf (attrsOf str);
        default = {};
        description = "RON values written to ~/.config/cosmic/<component>/v1/<key>";
      };
      panel = lib.genAttrs ["left" "center" "right"] (side:
        lib.mkOption {
          type = with lib.types; listOf str;
          default = [];
          description = "Applet ids on the ${side} of the top panel";
        });
      outputs = lib.mkOption {
        type = lib.types.attrsOf (lib.types.submodule {
          options = {
            width = lib.mkOption {
              type = lib.types.int;
              description = "Mode width, as listed by `cosmic-randr list` (before any rotation)";
            };
            height = lib.mkOption {
              type = lib.types.int;
              description = "Mode height, as listed by `cosmic-randr list` (before any rotation)";
            };
            scale = lib.mkOption {
              type = lib.types.float;
              description = "Display scale, ie. 1.5 for 150%";
            };
          };
        });
        default = {};
        description = "Per-output display settings, by connector name";
      };
    };

    config = {
      CertifiKate.cosmic = {
        settings = lib.mapAttrs (_: lib.mapAttrs (_: lib.mkDefault)) settings;

        panel = {
          left = ["com.system76.CosmicAppletWorkspaces"];
          center = ["com.system76.CosmicAppletTime"];
          right = [
            "com.system76.CosmicAppletStatusArea"
            "com.system76.CosmicAppletTiling"
            "com.system76.CosmicAppletAudio"
            "com.system76.CosmicAppletNetwork"
            "com.system76.CosmicAppletBluetooth"
            "com.system76.CosmicAppletBattery"
            "com.system76.CosmicAppletNotifications"
            "com.system76.CosmicAppletPower"
          ];
        };
      };

      systemd.user.services.cosmic-outputs = lib.mkIf (cfg.outputs != {}) {
        Unit = {
          Description = "Apply COSMIC display scale";
          PartOf = ["graphical-session.target"];
          After = ["graphical-session.target"];
        };
        Service = {
          Type = "oneshot";
          ExecStart = "${applyOutputs}";
        };
        Install.WantedBy = ["graphical-session.target"];
      };

      home.file.".config/bg/${wallpaper}" = {
        source = ./wallpapers/${wallpaper};
      };

      # COSMIC has its own bluetooth applet, so drop blueman's duplicate tray icon (GNOME keeps it)
      xdg.configFile."autostart/blueman.desktop".text = ''
        [Desktop Entry]
        Type=Application
        Name=Blueman Applet
        Icon=blueman
        Exec=blueman-applet
        NotShowIn=COSMIC;
      '';

      home.activation.cosmicSettings = lib.hm.dag.entryAfter ["writeBoundary"] writeSettings;
    };
  };
}
