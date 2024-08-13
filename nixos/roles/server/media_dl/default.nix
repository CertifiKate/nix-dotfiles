let
  base_project_dir = "/services/";
  sonarr_project_dir = "${base_project_dir}/sonarr";
  radarr_project_dir = "${base_project_dir}/sonarr";
  jellyseer_project_dir = "${base_project_dir}/sonarr";
in {
  # TODO: Can we make the declarative somehow?
  services.sonarr = {
    enable = true;
    dataDir = "${sonarr_project_dir}/data";
    group = "media";
    openFirewall = true;
  };

  services.radarr = {
    enable = true;
    dataDir = "${radarr_project_dir}/data";
    group = "media";
    openFirewall = true;
  };
}
