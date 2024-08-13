{pkgs, ...}: let
  project_dir = "/services/jellyfin";
  data_dir = "${project_dir}/data";
in {
  # Setup backup service
  # CertifiKate.backup_service = {
  #   paths = [
  #     "${project_dir}"
  #   ];
  # };

  users.users.jellyfin = {
    extraGroups = [
      "video"
      "render"
      "input"
    ];
  };

  services.jellyfin = {
    enable = true;
    group = "media";
    openFirewall = true;
    dataDir = "${data_dir}";
  };

  # environment.systemPackages = [
  #   # pkgs.jellyfin
  #   pkgs.jellyfin-web
  #   pkgs.jellyfin-ffmpeg
  # ];
}
