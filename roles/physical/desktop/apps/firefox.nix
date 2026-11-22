{config, ...}: let
  inherit (config.meta) user;
in {
  flake.modules.homeManager."roles/physical/desktop/apps" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.CertifiKate) theme look;
    inherit (config.colorScheme) palette variant;
    c = lib.mapAttrs (_: hex: "#${hex}") palette;
    isDark = variant == "dark";

    newTabBackground = pkgs.runCommand "newtab-background.jpg" {nativeBuildInputs = [pkgs.imagemagick];} ''
      magick ${look.wallpaper} -resize 1920x -blur 0x6 -fill '${c.base00}' -colorize 45% -quality 85 $out
    '';

    chromeVars = lib.concatStrings (lib.mapAttrsToList (var: colour: "  --${var}: ${colour} !important;\n") {
      "toolbox-background-color" = c.base00;
      "toolbox-background-color-inactive" = c.base00;
      "toolbox-text-color" = c.base05;
      "toolbox-text-color-inactive" = c.base04;
      "toolbar-background-color" = c.base01;
      "toolbar-text-color" = c.base05;
      "toolbarbutton-icon-fill" = c.base05;
      "tab-background-color-selected" = c.base02;
      "tab-text-color-selected" = c.base05;
      "tab-line-selected-color" = c.base0D;
      "tabpanel-background-color" = c.base00;
      "toolbar-field-background-color" = c.base00;
      "toolbar-field-text-color" = c.base05;
      "toolbar-field-background-color-focus" = c.base00;
      "toolbar-field-text-color-focus" = c.base05;
      "toolbar-field-border-color-focus" = c.base0D;
      "panel-background-color" = c.base01;
      "panel-text-color" = c.base05;
      "panel-border-color" = c.base02;
      "urlbarview-background-color-selected" = c.base02;
      "urlbarview-text-color-selected" = c.base05;
      "sidebar-background-color" = c.base01;
      "sidebar-text-color" = c.base05;
      "color-accent-primary" = c.base0D;
      "color-accent-primary-hover" = c.base0C;
      "color-accent-primary-active" = c.base0C;
      "button-text-color-primary" = c.base00;
      "focus-outline-color" = c.base0D;
    });
  in {
    programs.firefox = {
      enable = true;
      configPath = ".mozilla/firefox";
      policies = {
        ExtensionSettings = {
          # Bitwarden
          "{446900e4-71c2-419f-a6a7-df9c091e268b}" = {
            installation_mode = "force_installed";
            install_url = "https://addons.mozilla.org/firefox/downloads/latest/bitwarden-password-manager/latest.xpi";
            default_area = "navbar";
          };
        };
        OfferToSaveLogins = false;
        PasswordManagerEnabled = false;
        DisplayBookmarksToolbar = true;
        NoDefaultBookmarks = true;
      };
      profiles."${user}" = lib.mkMerge [
        (lib.mkIf (theme != null) {
          settings = {
            "toolkit.legacyUserProfileCustomizations.stylesheets" = true;
            "extensions.activeThemeID" =
              if isDark
              then "firefox-compact-dark@mozilla.org"
              else "firefox-compact-light@mozilla.org";
            "layout.css.prefers-color-scheme.content-override" =
              if isDark
              then 0
              else 1;
          };
          userChrome = ":root {\n${chromeVars}}\n";
          userContent = ''
            @-moz-document url("about:home"), url("about:newtab"), url("about:privatebrowsing") {
              :root {
                --newtab-background-color: ${c.base00} !important;
                --newtab-background-color-secondary: ${c.base01} !important;
                --newtab-text-primary-color: ${c.base05} !important;
              }
              body {
                background: ${c.base00} url("file://${newTabBackground}") center / cover fixed no-repeat !important;
              }
            }
          '';
        })
        {
          search = {
            force = true;
            engines = {
              "Nix Packages" = {
                urls = [
                  {
                    template = "https://search.nixos.org/packages?channel=unstable";
                    params = [
                      {
                        name = "type";
                        value = "packages";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@np"];
              };
              "Nix Options" = {
                urls = [
                  {
                    template = "https://search.nixos.org/options?channel=unstable";
                    params = [
                      {
                        name = "sort";
                        value = "alpha_asc";
                      }
                      {
                        name = "query";
                        value = "{searchTerms}";
                      }
                    ];
                  }
                ];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@no"];
              };
              "NixOS Wiki" = {
                urls = [
                  {
                    template = "https://wiki.nixos.org/w/index.php?search={searchTerms}";
                  }
                ];
                icon = "https://nixos.wiki/favicon.png";
                updateInterval = 24 * 60 * 60 * 1000;
                definedAliases = ["@nw"];
              };
              "Home Manager Options" = {
                urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";}];
                icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
                definedAliases = ["@hm"];
              };
              "wikipedia".metaData.alias = "@wiki";
              "google".metaData.hidden = true;
              "amazondotcom-us".metaData.hidden = true;
              "bing".metaData.hidden = true;
              "ebay".metaData.hidden = true;
            };
          };
        }
      ];
    };
  };
}
