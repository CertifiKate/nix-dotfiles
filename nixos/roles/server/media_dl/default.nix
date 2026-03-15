{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;

  base_project_dir = "/services";
  sonarr_project_dir = "${base_project_dir}/sonarr";
  radarr_project_dir = "${base_project_dir}/radarr";
  lidarr_project_dir = "${base_project_dir}/lidarr";
  prowlarr_project_dir = "${base_project_dir}/prowlarr";
  cleanuparr_project_dir = "${base_project_dir}/cleanuparr";
  qbittorrent_project_dir = "${base_project_dir}/qbittorrent";

  torrent_web_ui_port = 8080;
  torrent_vpn_port = 43418;
  torrent_vpn_namespace = "qbt-wg";
in {
  imports = [inputs.vpn-confinement.nixosModules.default];

  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${base_project_dir}"
      # For some reason we can't specify the jellyseerr directory...
      "/var/lib/jellyseerr"
    ];
  };

  # Add Wireguard config
  sops.secrets."wg_config" = {
    owner = "torrent";
    path = "/etc/wireguard/wg_config";
    sopsFile = "${secretsPath}/secrets/media_dl.yaml";
  };
  users.users = {
    torrent = {
      isSystemUser = true;
      group = "media";
    };
  };

  systemd = {
    tmpfiles.rules = [
      "d ${base_project_dir} +070 root media"
      "d ${qbittorrent_project_dir} +770 torrent media"
    ];
  };

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

  services.lidarr = {
    enable = true;
    dataDir = "${lidarr_project_dir}/data";
    group = "media";
    openFirewall = true;
  };

  services.jellyseerr = {
    enable = true;
    openFirewall = true;
  };

  services.qbittorrent = {
    enable = true;
    profileDir = "${qbittorrent_project_dir}/data";
    user = "torrent";
    group = "media";
    webuiPort = torrent_web_ui_port;
    torrentingPort = torrent_vpn_port;
    openFirewall = true;
  };

  vpnNamespaces.${torrent_vpn_namespace} = {
    enable = true;
    wireguardConfigFile = config.sops.secrets."wg_config".path;
    accessibleFrom = [
      "192.168.0.0/16"
    ];
    portMappings = [
      {
        from = torrent_web_ui_port;
        to = torrent_web_ui_port;
        protocol = "tcp";
      }
    ];
  };

  networking.firewall.allowedTCPPorts = [torrent_web_ui_port];

  systemd.services.qbittorrent-bridge = {
    description = "Bridge Host Port 8080 to vpn-confinement namespace";
    after = ["${torrent_vpn_namespace}.service" "qbittorrent.service"];
    requires = ["${torrent_vpn_namespace}.service"];
    wantedBy = ["multi-user.target"];

    serviceConfig = {
      # This listens on the HOST's 0.0.0.0:8080
      # and executes a command inside the namespace to talk to qBittorrent's local port
      ExecStart = ''
        ${pkgs.socat}/bin/socat \
          TCP-LISTEN:${builtins.toString torrent_web_ui_port},fork,reuseaddr \
          EXEC:"${pkgs.iproute2}/bin/ip netns exec ${torrent_vpn_namespace} ${pkgs.socat}/bin/socat - TCP:192.168.15.1:${builtins.toString torrent_web_ui_port}"
      '';
      Restart = "always";
      User = "root"; # Required to enter the namespace
    };
  };

  systemd.services.qbittorrent.vpnConfinement = {
    enable = true;
    vpnNamespace = "${torrent_vpn_namespace}";
  };
  assertions = [
    {
      assertion = config.systemd.services ? qbittorrent;
      message = "systemd service 'qbittorrent' not found - the qbittorrent service name may have changed. This could bypass the VPN confinement!";
    }
  ];

  # Add automatic Cleanup
  virtualisation.oci-containers.containers = {
    cleanuparr = {
      autoStart = true;
      image = "ghcr.io/cleanuparr/cleanuparr:latest";
      volumes = [
        "${cleanuparr_project_dir}/data:/config"
        "/data:/data"
      ];
      ports = ["11011:11011"];
      environment = {
        TZ = config.time.timeZone;
      };
    };
  };
}
