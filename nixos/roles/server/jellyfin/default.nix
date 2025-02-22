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

  # 1. enable vaapi on OS-level
  nixpkgs.config.packageOverrides = pkgs: {
    vaapiIntel = pkgs.vaapiIntel.override {enableHybridCodec = true;};
  };

  environment.systemPackages = with pkgs; [
    libva-utils
    intel-gpu-tools
    intel-media-driver
  ];
  hardware.graphics = {
    enable = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-vaapi-driver
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
