{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.nixos."roles/physical/desktop/cosmic" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.home-manager.users.${user}.CertifiKate) look;
  in {
    # Enable the X11 windowing system.
    services.xserver.enable = true;

    # GDM's gnome-shell greeter adds ~5s to boot, so COSMIC's own takes over even alongside GNOME
    services.displayManager.gdm.enable = false;
    services.displayManager.cosmic-greeter.enable = true;
    security.pam.services.cosmic-greeter.enableGnomeKeyring = true;
    # The greeter copies the user's theme and wallpaper, but not the cursor
    systemd.services.greetd.environment.XCURSOR_THEME = look.cursor.name;

    # The greeter only reads AccountsService's copy of the avatar, and refuses symlinks
    systemd.tmpfiles.rules = ["C+ /var/lib/AccountsService/icons/${user} 0644 root root - ${./face.png}"];

    services.desktopManager.cosmic = {
      enable = true;
    };

    environment.systemPackages = [
      pkgs.playerctl # Used by the media key system actions
      look.cursor.package
    ];

    home-manager.users.${user} = {
      imports = [homeManager."roles/physical/desktop/cosmic"];
      CertifiKate.theme = lib.mkDefault "monet";
    };
  };

  flake.modules.homeManager."roles/physical/desktop/cosmic" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.CertifiKate.cosmic;
    inherit (config.CertifiKate) look;
    inherit (config.colorScheme) palette;
    wallpaper = baseNameOf look.wallpaper;
    font = f: "(family: \"${f.name}\", weight: Normal, stretch: Normal, style: Normal)";

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
        custom = shortcuts ([
            # i3
            (bind ["Super"] "Return" "System(Terminal)" "Open terminal")
            (bind ["Super"] "d" "System(Launcher)" "Open launcher")
            (bind ["Super" "Shift"] "q" "Close" "Close window")
            (bind ["Super"] "f" "Fullscreen" "Toggle fullscreen")
            # Floats the whole workspace, as COSMIC tiles per workspace - single windows float with Super+g
            (bind ["Super" "Shift"] "space" "ToggleTiling" "Toggle floating on workspace")
            (bind ["Super"] "e" "ToggleOrientation" "Toggle split orientation")
            (bind ["Super" "Shift"] "e" "System(LogOut)" "Log out")
            (bind ["Super"] "t" "ToggleTiling" "Toggle tiling on workspace")
            (bind ["Super"] "m" "Maximize" "Toggle maximized")
            (bind ["Super" "Shift"] "s" "System(Screenshot)" "Screenshot")
            (bind ["Super"] "space" "System(Launcher)" "Open launcher")
          ]
          # Hand the power key to logind instead (needs PowerKeyIgnoreInhibited, as cosmic-session always inhibits it)
          ++ lib.optional (!cfg.powerKeyDialog) (bind [] "XF86PowerOff" "Disable" "Power key handled by logind")
          ++ map (s: bind s.modifiers s.key s.action s.description) cfg.shortcuts);
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
              # The extension's unlock popout, which otherwise tiles in beside Firefox at login
              (appid: "^firefox$", title: "Bitwarden", enabled: true),
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
        # Insets applets so the active workspace highlight doesn't run into the bar's edges
        padding = "4";
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
      "com.system76.CosmicTheme.Mode" = {
        is_dark = "true";
      };
      "com.system76.CosmicTk" = {
        icon_theme = "\"${look.icons.name}\"";
        interface_font = font look.fonts.sans;
        monospace_font = font look.fonts.mono;
      };

      "com.system76.CosmicTerm" = let
        c = name: "\"#${palette.${name}}\"";
        ansi = black: white: ''
          (
              black: ${c black},
              red: ${c "base08"},
              green: ${c "base0B"},
              yellow: ${c "base0A"},
              blue: ${c "base0D"},
              magenta: ${c "base0E"},
              cyan: ${c "base0C"},
              white: ${c white},
          )'';
      in {
        font_name = "\"${look.fonts.mono.name}\"";
        syntax_theme_dark = "\"${config.colorScheme.name}\"";
        color_schemes_dark = ''
          {
              0: (
                  name: "${config.colorScheme.name}",
                  foreground: ${c "base05"},
                  background: ${c "base00"},
                  cursor: ${c "base05"},
                  dim_foreground: ${c "base04"},
                  normal: ${ansi "base01" "base05"},
                  bright: ${ansi "base03" "base07"},
              ),
          }
        '';
      };

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

    theme = let
      c = name: "\"#${config.colorScheme.palette.${name}}FF\"";
    in
      pkgs.writeText "${config.colorScheme.slug}.ron" ''
        (
            palette: Dark((
                name: "${config.colorScheme.slug}",
                bright_red: ${c "base08"},
                bright_green: ${c "base0B"},
                bright_orange: ${c "base09"},
                gray_1: ${c "base01"},
                gray_2: ${c "base02"},
                neutral_0: "#000000FF",
                neutral_1: "#030303FF",
                neutral_2: "#161616FF",
                neutral_3: "#2E2E2EFF",
                neutral_4: "#484848FF",
                neutral_5: "#636363FF",
                neutral_6: "#808080FF",
                neutral_7: "#9E9E9EFF",
                neutral_8: "#BEBEBEFF",
                neutral_9: "#DEDEDEFF",
                neutral_10: "#FFFFFFFF",
                accent_blue: ${c "base0D"},
                accent_indigo: ${c "base0D"},
                accent_purple: ${c "base0E"},
                accent_pink: ${c "base08"},
                accent_red: ${c "base08"},
                accent_orange: ${c "base09"},
                accent_yellow: ${c "base0A"},
                accent_green: ${c "base0C"},
                accent_warm_grey: ${c "base0F"},
                ext_warm_grey: ${c "base0F"},
                ext_orange: ${c "base09"},
                ext_yellow: ${c "base0A"},
                ext_blue: ${c "base0D"},
                ext_purple: ${c "base0E"},
                ext_pink: ${c "base08"},
                ext_indigo: ${c "base0D"},
            )),
            spacing: (
                space_none: 4,
                space_xxxs: 8,
                space_xxs: 12,
                space_xs: 16,
                space_s: 24,
                space_m: 32,
                space_l: 48,
                space_xl: 64,
                space_xxl: 128,
                space_xxxl: 160,
            ),
            corner_radii: (
                radius_0: (0.0, 0.0, 0.0, 0.0),
                radius_xs: (4.0, 4.0, 4.0, 4.0),
                radius_s: (10.0, 10.0, 10.0, 10.0),
                radius_m: (12.0, 12.0, 12.0, 12.0),
                radius_l: (12.0, 12.0, 12.0, 12.0),
                radius_xl: (16.0, 16.0, 16.0, 16.0),
            ),
            neutral_tint: Some(${c "base03"}),
            bg_color: Some(${c "base00"}),
            primary_container_bg: Some(${c "base01"}),
            secondary_container_bg: Some(${c "base02"}),
            text_tint: Some(${c "base05"}),
            accent: Some(${c "base0D"}),
            success: Some(${c "base0B"}),
            warning: Some(${c "base0A"}),
            destructive: Some(${c "base08"}),
            frosted: Medium,
            gaps: (8, 8),
            active_hint: 2,
            window_hint: Some(${c "base0C"}),
            frosted_windows: false,
            frosted_system_interface: false,
            // Frosting the panel makes the compositor reject its corner radius and drop it at login
            frosted_panel: false,
            frosted_applets: true,
            frosted_maximized_apps: false,
            alpha_map: (
                extremely_low: 0.9,
                extremely_low_2: 0.87692,
                very_low: 0.85385,
                very_low_2: 0.83076,
                low: 0.80769,
                low_2: 0.78461,
                medium: 0.76154,
                medium_2: 0.73846,
                high: 0.71538,
                high_2: 0.69231,
                very_high: 0.66023,
                very_high_2: 0.64615,
                extremely_high: 0.62308,
                extremely_high_2: 0.6,
            ),
        )
      '';

    # Only the Settings app builds the full theme, so import it - only on change, as that resets manual tweaks
    applyTheme = ''
      if ! cmp -s ${theme} "$HOME/.config/cosmic/.theme.ron"; then
        run ${pkgs.cosmic-settings}/bin/cosmic-settings appearance import ${theme}
        run install -m644 ${theme} "$HOME/.config/cosmic/.theme.ron"
      fi
    '';

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

    # COSMIC doesn't read iio-sensor-proxy itself, so follow the accelerometer and set the transform
    autoRotate = name: output:
      pkgs.writeShellScript "cosmic-autorotate-${name}" ''
        ${pkgs.iio-sensor-proxy}/bin/monitor-sensor --accel | while read -r line; do
          case "$line" in
            *": normal"*) transform=normal ;;
            *": left-up"*) transform=rotate90 ;;
            *": bottom-up"*) transform=rotate180 ;;
            *": right-up"*) transform=rotate270 ;;
            *) continue ;;
          esac
          ${pkgs.cosmic-randr}/bin/cosmic-randr mode ${name} ${toString output.width} ${toString output.height} \
            --scale ${lib.strings.floatToString output.scale} --transform "$transform"
        done
      '';
  in {
    imports = [
      homeManager."roles/physical/desktop"
    ];

    options.CertifiKate.cosmic = {
      shortcuts = lib.mkOption {
        type = lib.types.listOf (lib.types.submodule {
          options = {
            modifiers = lib.mkOption {
              type = with lib.types; listOf str;
              default = [];
            };
            key = lib.mkOption {type = lib.types.str;};
            action = lib.mkOption {
              type = lib.types.str;
              description = "RON action, ie. System(AppLibrary)";
            };
            description = lib.mkOption {type = lib.types.str;};
          };
        });
        default = [];
        description = "Extra custom shortcuts, added to the shared set";
      };
      powerKeyDialog = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Show COSMIC's shutdown dialog on the power key, rather than leaving it to logind's HandlePowerKey";
      };
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
            autoRotate = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Rotate the output to follow the accelerometer";
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

      systemd.user.services =
        {
          cosmic-outputs = lib.mkIf (cfg.outputs != {}) {
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
        }
        // lib.mapAttrs' (name: output:
          lib.nameValuePair "cosmic-autorotate-${name}" {
            Unit = {
              Description = "Rotate ${name} to follow the accelerometer";
              PartOf = ["graphical-session.target"];
              After = ["cosmic-outputs.service"];
            };
            Service = {
              ExecStart = "${autoRotate name output}";
              Restart = "on-failure";
              RestartSec = 2;
            };
            Install.WantedBy = ["graphical-session.target"];
          }) (lib.filterAttrs (_: output: output.autoRotate) cfg.outputs);

      home.file.".config/bg/${wallpaper}".source = look.wallpaper;

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
      home.activation.cosmicTheme = lib.hm.dag.entryAfter ["cosmicSettings"] applyTheme;
    };
  };
}
