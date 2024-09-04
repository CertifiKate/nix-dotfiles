{pkgs, ...}: let
  project_dir = "/services/jellyfin";

  data_dir = "${project_dir}/data";
  config_dir = "${project_dir}/config";
in {
  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${project_dir}"
    ];
  };

  hardware.graphics = {
    # hardware.opengl in 24.05
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver # previously vaapiIntel
      vaapiVdpau
      intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
      vpl-gpu-rt # QSV on 11th gen or newer
      intel-media-sdk # QSV up to 11th gen
    ];
  };

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
    configDir = "${config_dir}";
  };
}
