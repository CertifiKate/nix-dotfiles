{lib, ...}: {
  options.CertifiKate.roles.server = {
    # ==============================
    # Server role toggle options
    auth.enable = lib.mkEnableOption "Authentication service (Authelia + LDAP)";
    backup.enable = lib.mkEnableOption "Backup server services";
    budget.enable = lib.mkEnableOption "Budget management service (Actual Budget)";
    cloudflared.enable = lib.mkEnableOption "Cloudflared tunnel client";
    deployment_host.enable = lib.mkEnableOption "Deployment host services";
    jellyfin.enable = lib.mkEnableOption "Jellyfin media server";
    mdns_repeater.enable = lib.mkEnableOption "mDNS repeater service for local network discovery";
    media_dl.enable = lib.mkEnableOption "Media download services (Sonarr, Radarr, etc)";
    minecraft.enable = lib.mkEnableOption "Minecraft server";
    nix_builder.enable = lib.mkEnableOption "Nix builder services";
    proxy.enable = lib.mkEnableOption "Reverse proxy services (Traefik)";

    # ==============================
    # Routing definitions for traefik and authelia
    routes = lib.mkOption {
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
        };
      });
      default = {};
    };
  };
}
