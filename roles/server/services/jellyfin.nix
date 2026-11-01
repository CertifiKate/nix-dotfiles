{
  homelab.routes.jellyfin = {
    host = "media";
    dest = "http://media-01.srv:8096";
    rules = [
      {
        policy = "bypass";
      }
    ];
    dashboard = {
      name = "Jellyfin";
      description = "Watch TV and movies";
      icon = "sh-jellyfin";
      group = "Media";
    };
  };

  flake.modules.nixos."roles/server/services/jellyfin" = {pkgs, ...}: let
    project_dir = "/services/jellyfin";

    data_dir = "${project_dir}/data";
    config_dir = "${project_dir}/config";
  in {
    CertifiKate.persist.directories = [
      "${project_dir}"
    ];
    # No point backing up cache, but also no point regenerating it each boot
    CertifiKate.persist.localDirectories = ["/var/cache/jellyfin"];

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
        libva-vdpau-driver
        intel-compute-runtime # OpenCL filter support (hardware tonemapping and subtitle burn-in)
        vpl-gpu-rt # QSV on 11th gen or newer
        # intel-media-sdk # QSV up to 11th gen
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
  };
}
