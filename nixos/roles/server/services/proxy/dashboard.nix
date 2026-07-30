{
  private,
  lib,
  config,
  ...
}: let
  project_tld = "${private.project_tld}";

  routes = config.CertifiKate.roles.server.routes;

  dashboardRoutes = lib.filterAttrs (_: r: r.dashboard != null) routes;
  groups = lib.unique (
    lib.mapAttrsToList (_: r: r.dashboard.group) dashboardRoutes
  );

  # For a given group, return the list of { "Name" = { ... }; } entries
  entriesForGroup = group:
    lib.mapAttrsToList (
      _: r: {
        "${r.dashboard.name}" = {
          description = r.dashboard.description;
          href = "https://${
            if r.host == ""
            then ""
            else "${r.host}."
          }${project_tld}";
          icon = r.dashboard.icon;
        };
      }
    ) (lib.filterAttrs (_: r: r.dashboard.group == group) dashboardRoutes);

  # Final list: [ { "Group" = [ entries ]; } ]
  homepageServices = map (g: {"${g}" = entriesForGroup g;}) groups;
in {
  config = lib.mkIf config.CertifiKate.roles.server.proxy.enable {
    CertifiKate.roles.server.routes.homepage = {
      host = ""; # Empty host means the root of the project_tld
      dest = "http://127.0.0.1:8082";
      rules = [
        {
          policy = "one_factor";
        }
      ];
    };

    services.homepage-dashboard = {
      enable = true;
      settings = [];
      openFirewall = false;
      listenPort = 8082;
      services = homepageServices;
      widgets = [
        {
          search = {
            provider = "duckduckgo";
            target = "_blank";
          };
        }
      ];
    };
  };
}
