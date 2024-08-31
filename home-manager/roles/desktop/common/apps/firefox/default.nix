{pkgs, ...}: {
  programs.firefox = {
    enable = true;
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
    profiles.kate = {
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
            iconUpdateURL = "https://nixos.wiki/favicon.png";
            updateInterval = 24 * 60 * 60 * 1000;
            definedAliases = ["@nw"];
          };
          "Home Manager Options" = {
            urls = [{template = "https://home-manager-options.extranix.com/?query={searchTerms}&release=master";}];
            icon = "${pkgs.nixos-icons}/share/icons/hicolor/scalable/apps/nix-snowflake.svg";
            definedAliases = ["@hm"];
          };
          "Wikipedia (en)".metaData.alias = "@wiki";
          "Google".metaData.hidden = true;
          "Amazon.com".metaData.hidden = true;
          "Bing".metaData.hidden = true;
          "eBay".metaData.hidden = true;
        };
      };
    };
  };
}
