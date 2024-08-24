{
  pkgs,
  inputs,
  lib,
  private,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";
  project_dir = "/config/proxy";
  config_dir = "${project_dir}/config";
  data_dir = "${project_dir}/data";
in {
  environment.systemPackages = with pkgs; [
    traefik
  ];

  # Setup backup service
  CertifiKate.backup_service = {
    paths = [
      "${project_dir}"
    ];
  };

  sops.secrets."proxy_traefik_env" = {
    owner = "traefik";
    sopsFile = "${secretsPath}/secrets/proxy.yaml";
  };

  networking.firewall.allowedTCPPorts = [80 443];

  # Allow traefik to access config data dir
  systemd = {
    tmpfiles.rules = [
      # Allow anyone to access the base directory
      "d ${project_dir} 777 root root"
      "d ${config_dir} 1750 traefik traefik"
      "d ${data_dir} 1750 traefik traefik"
    ];
  };

  services.traefik = let
    # TODO: Handle static service/routers (traefik dashboard, authelia?)
    defaultServices = {
    };

    # TODO: These will be moved to dns entries after they've been migrated
    services = {
      # Core
      authelia = {
        host = "auth";
        dest = "http://auth-01.srv:9091";
        auth = false;
      };

      gotify = {
        host = "gotify";
        dest = "http://192.168.10.30:3300";
        auth = false;
      };

      # Util
      tandoor = {
        host = "recipes";
        dest = "http://192.168.10.30:4001";
      };

      # Media
      sonarr = {
        host = "sonarr";
        dest = "http://media-02.srv:8989";
      };

      radarr = {
        host = "radarr";
        dest = "http://media-02.srv:7878";
      };

      prowlarr = {
        host = "prowlarr";
        dest = "http://192.168.10.51:9696";
      };

      qbittorrent = {
        host = "torrent";
        dest = "http://192.168.10.51:8080";
      };

      library = {
        host = "library";
        dest = "http://192.168.10.51:8083";
        auth = false;
      };

      jellyseer = {
        host = "jellyseer";
        dest = "http://192.168.10.51:5055";
        auth = false;
      };

      jellyfin = {
        host = "media";
        dest = "http://192.168.10.50:8096";
        auth = false;
      };

      # Home Automation
      home = {
        host = "home";
        dest = "http://192.168.10.41:8123";
        auth = false;
      };
    };

    # TODO: Can we add back the router-x service-x prefix?
    mkRouters = name: cfg: {
      service = "${name}";
      rule = "${cfg.rule or "Host(`${cfg.host}.${project_tld}`)"}";
      entryPoints = "webHttps";
      priority = "10";

      middlewares = lib.mkIf (cfg.auth or true) [
        "authelia@file"
      ];

      tls = {
        certResolver = "letsEncrypt";
        domains = [
          {
            main = "${project_tld}";
            sans = ["*.${project_tld}"];
          }
        ];
      };
    };

    mkServices = name: cfg: {
      loadBalancer = {servers = [{url = "${cfg.dest}";}];};
    };

    allRouters = lib.mapAttrs mkRouters services;
    allServices = lib.mapAttrs mkServices services;
  in rec {
    enable = true;
    dataDir = "${data_dir}";
    environmentFiles = [
      "/run/secrets/proxy_traefik_env"
    ];
    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          proxyProtocol.trustedIPs = ["192.168.10.15/32"];
          forwardedHeaders.trustedIPs = ["192.168.10.15/32"];
          http.redirections = {
            entryPoint = {
              to = "webHttps";
              scheme = "https";
              permanent = false;
            };
          };
        };
        webHttps = {
          address = ":443";
          proxyProtocol.trustedIPs = ["192.168.10.15/32"];
          forwardedHeaders.trustedIPs = ["192.168.10.15/32"];
        };
      };

      api = {
        dashboard = true;
        insecure = true;
      };

      certificatesResolvers.letsEncrypt.acme = {
        storage = "${config_dir}/acme.json";
        dnsChallenge = {
          provider = "cloudflare";
          delayBeforeCheck = "0";
        };
      };

      log.filePath = "${data_dir}/log";
      log.level = "WARN";
      accessLog.filePath = "${data_dir}/accesslog";
    };

    dynamicConfigOptions = {
      http = {
        middlewares = {
          authelia.forwardAuth = {
            address = "http://auth-01.srv:9091/api/authz/forward-auth";
            trustForwardHeader = true;
            authResponseHeaders = [
              "Remote-User"
              "Remote-Groups"
              "Remote-Email"
              "Remote-Name"
            ];
          };
        };

        routers = allRouters;
        services = allServices;
      };
    };
  };
}
