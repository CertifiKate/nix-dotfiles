let
  base_project_dir = "/services";
  sonarr_project_dir = "${base_project_dir}/sonarr";
  radarr_project_dir = "${base_project_dir}/radarr";
  jellyseer_project_dir = "${base_project_dir}/jellyseer";
  # TODO: Unused
  media_dir = "/data";
in {
  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${base_project_dir}"
    ];
  };

  # Allow traefik to access config data dir
  systemd = {
    tmpfiles.rules = [
      "d ${base_project_dir} +070 root media"
    ];
  };

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
