{
  private,
  lib,
  config,
  ...
}: let
  project_tld = "${private.project_tld}";
in {
  config = lib.mkMerge [
    (
      lib.mkIf config.CertifiKate.roles.server.proxy.enable {
        services.homepage-dashboard = {
          enable = true;
          settings = [];

          openFirewall = true;
          listenPort = 8082;
          services = [
            {
              "Settings" = [
                {
                  "Authelia" = {
                    description = "Authelia - Manage logins";
                    href = "https://auth.${project_tld}";
                    icon = "sh-authelia";
                  };
                }
              ];
            }
            {
              "Media" = [
                {
                  "Jellyfin" = {
                    description = "Jellyfin - Watch TV and Movies";
                    href = "https://media.${project_tld}";
                    icon = "sh-jellyfin";
                  };
                }
                {
                  "Jellyseerr" = {
                    description = "Jellyseerr - Media request management";
                    href = "https://jellyseer.${project_tld}";
                    icon = "sh-jellyseerr";
                  };
                }
              ];
            }
          ];
          widgets = [
            {
              search = {
                provider = "duckduckgo";
                target = "_blank";
              };
            }
          ];
        };
      }
    )
  ];
}
# # Register traefik route for dashboard
# CertifiKate.roles.server.traefik_routes = {
#   dashboard = {
#     router = {
#       rule = "Host(`${project_tld}`)";
#     };
#     service = {
#       dest = "http://127.0.0.1:8082";
#     };
#   };
# };

