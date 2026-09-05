{
  inputs,
  config,
  pkgs,
  lib,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;

  base_project_dir = "/services";
  sonarr_project_dir = "${base_project_dir}/sonarr";
  radarr_project_dir = "${base_project_dir}/radarr";
  lidarr_project_dir = "${base_project_dir}/lidarr";
  prowlarr_project_dir = "${base_project_dir}/prowlarr";
  cleanuparr_project_dir = "${base_project_dir}/cleanuparr";
  qbittorrent_project_dir = "${base_project_dir}/qbittorrent";
  seerr_project_dir = "${base_project_dir}/seerr";

  torrent_web_ui_port = 8080;
  torrent_vpn_port = 43418;
  torrent_vpn_namespace = "qbt-wg";
in {
  imports = [
    inputs.vpn-confinement.nixosModules.default
  ];

  config = lib.mkMerge [
    {
      CertifiKate.roles.server.routes = {
        sonarr = {
          host = "sonarr";
          dest = "http://media-02.srv:8989";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Sonarr";
            description = "TV show download management";
            icon = "sh-sonarr";
            group = "Media Downloads";
          };
        };
        radarr = {
          host = "radarr";
          dest = "http://media-02.srv:7878";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Radarr";
            description = "Movie download management";
            icon = "sh-radarr";
            group = "Media Downloads";
          };
        };
        prowlarr = {
          host = "prowlarr";
          dest = "http://media-02.srv:9696";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Prowlarr";
            description = "Indexer management";
            icon = "sh-prowlarr";
            group = "Media Downloads";
          };
        };
        lidarr = {
          host = "lidarr";
          dest = "http://media-02.srv:8686";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Lidarr";
            description = "Music download management";
            icon = "sh-lidarr";
            group = "Media Downloads";
          };
        };
        qbittorrent = {
          host = "torrent";
          dest = "http://media-02.srv:8080";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "qBittorrent";
            description = "Torrent client";
            icon = "sh-qbittorrent";
            group = "Media Downloads";
          };
        };
        cleanuparr = {
          host = "cleanuparr";
          dest = "http://media-02.srv:11011";
          rules = [
            {
              subject = [
                "group:media_admin"
                "group:admin"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Cleanuparr";
            description = "Automated media library cleanup";
            icon = "sh-cleanuparr";
            group = "Media Downloads";
          };
        };
        seerr = {
          host = "jellyseer";
          dest = "http://media-02.srv:5055";
          rules = [
            {
              subject = [
                "group:media"
              ];
              policy = "one_factor";
            }
          ];
          dashboard = {
            name = "Jellyseerr";
            description = "Request movies and TV shows";
            icon = "sh-jellyseerr";
            group = "Media";
          };
        };
        library = {
          host = "library";
          dest = "http://media-02.srv:8083";
          rules = [
            {
              policy = "bypass";
            }
          ];
          dashboard = {
            name = "Calibre Web";
            description = "Browse and read ebooks";
            icon = "sh-calibre-web";
            group = "Media";
          };
        };
      };
    }
    (lib.mkIf config.CertifiKate.roles.server.media_dl.enable {
      # Setup backup service
      CertifiKate.modules.backup_service = {
        paths = [
          "${base_project_dir}"
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

      services.prowlarr = {
        enable = true;
        dataDir = "${prowlarr_project_dir}/data";
        openFirewall = true;
      };

      services.seerr = {
        enable = true;
        configDir = "${seerr_project_dir}/data";
        openFirewall = true;
      };
      systemd.services."seerr".serviceConfig.ReadWritePaths = ["${seerr_project_dir}/data"];
      systemd.services."seerr".serviceConfig.Group = "media";

      services.qbittorrent = {
        enable = true;
        profileDir = "${qbittorrent_project_dir}/data";
        user = "torrent";
        group = "media";
        webuiPort = torrent_web_ui_port;
        torrentingPort = torrent_vpn_port;
        openFirewall = true;
      };
      # Ensure qbittorrent can access config and data directories with the correct permissions
      systemd.services.qbittorrent.serviceConfig = {
        PrivateUsers = lib.mkForce false;
        ReadWritePaths = lib.mkForce [
          "/services/qbittorrent"
          "/data"
          "/data/Downloads"
        ];
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
          {
            from = torrent_vpn_port;
            to = torrent_vpn_port;
            protocol = "tcp";
          }
          {
            from = torrent_vpn_port;
            to = torrent_vpn_port;
            protocol = "udp";
          }
        ];
      };

      networking.firewall.allowedTCPPorts = [torrent_web_ui_port];

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
    })
  ];
}
