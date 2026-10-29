#
# Routing definitions for traefik (proxy) and authelia (auth)
# Declared at the flake level so any service module can add a route, regardless of which host it runs on
#
{lib, ...}: {
  options.homelab.routes = lib.mkOption {
    type = lib.types.attrsOf (lib.types.submodule {
      options = {
        host = lib.mkOption {
          type = lib.types.str;
          description = "Domain prefix (e.g., 'sonarr' becomes 'sonarr.example.com')";
        };
        dest = lib.mkOption {
          type = lib.types.str;
          description = "Backend destination URL (e.g., 'http://media-02.srv:8989')";
        };
        rules = lib.mkOption {
          type = lib.types.listOf (lib.types.submodule {
            options = {
              subject = lib.mkOption {
                default = [];
                type = lib.types.listOf lib.types.str;
                description = "List of subjects (e.g., 'group:admin')";
              };
              policy = lib.mkOption {
                type = lib.types.enum ["bypass" "one_factor" "two_factor" "deny"];
                description = "Access policy for this route";
              };
            };
          });
          default = [];
          description = "Authorization rules for this route";
        };
        dashboard = lib.mkOption {
          default = null;
          description = "Optional homepage-dashboard entry for this route";
          type = lib.types.nullOr (lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Display name shown on the dashboard";
              };
              description = lib.mkOption {
                type = lib.types.str;
                description = "Short description shown under the name";
              };
              icon = lib.mkOption {
                type = lib.types.str;
                description = "Icon identifier (e.g., 'sh-sonarr' for selfh.st icons)";
              };
              group = lib.mkOption {
                type = lib.types.str;
                description = "Dashboard group/category this service belongs to";
              };
            };
          });
        };
      };
    });
    default = {};
  };

  # Additional routes for when they aren't available in other modules (ie. Home Assistant)
  config.homelab.routes.home = {
    host = "home";
    dest = "http://home-02.srv";
    rules = [
      {
        policy = "bypass";
      }
    ];
  };
}
