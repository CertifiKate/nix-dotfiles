{
  pkgs,
  inputs,
  lib,
  private,
  config,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";
  project_dir = "/services/proxy";
  config_dir = "${project_dir}/config";
  data_dir = "${project_dir}/data";
in {
  imports = [
    ./dashboard.nix
  ];

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
    services = {
      # Core
      authelia = {
        host = "auth";
        dest = "http://auth-01.srv:9091";
        auth = false;
      };

      ldap = {
        host = "ldap";
        dest = "http://auth-01.srv:17170";
      };

      gotify = {
        host = "gotify";
        dest = "http://192.168.10.30:3300";
        auth = false;
      };

      dashboard = {
        rule = "Host(`${project_tld}`)";
        dest = "http://127.0.0.1:8082";
      };

      # Util
      tandoor = {
        host = "recipes";
        dest = "http://192.168.10.30:4001";
      };

      actual = {
        host = "actualbudget";
        dest = "http://util-01.srv:5006";
        auth = false;
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
        dest = "http://media-02.srv:5055";
      };

      jellyfin = {
        host = "media";
        dest = "http://media-01.srv:8096";
        auth = false;
      };

      # Home Automation
      home = {
        host = "home";
        dest = "http://192.168.10.41:8123";
        auth = false;
      };
    };

    mkRouters = name: cfg: {
      service = "${name}";
      rule = "${cfg.rule or "Host(`${cfg.host}.${project_tld}`)"}";
      priority = "128";
      entryPoints = "webHttps";

      middlewares =
        [
          "error-pages@file"
        ]
        ++ lib.optionals (cfg.auth or true) [
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

    defaultRouters = {
      # TODO: Look into this being broken
      # traefik = {
      #   service = "api@internal";
      #   rule = "Host(`traefik.${project_tld}`)";
      #   entryPoints = "webHttps";
      #   priority = "10";
      #   tls = {
      #     certResolver = "letsEncrypt";
      #     domains = [
      #       {
      #         main = "${project_tld}";
      #         sans = ["*.${project_tld}"];
      #       }
      #     ];
      #   };
      # };
      error-pages = {
        service = "error-pages";
        rule = "HostRegexp(`.+`)";
        entryPoints = "webHttps";
        priority = "64";
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
    };

    defaultServices = {
      error-pages = {
        loadBalancer = {servers = [{url = "http://127.0.0.1:8081";}];};
      };
    };

    customRouters = lib.mapAttrs mkRouters services;
    allRouters = customRouters // defaultRouters;

    customServices = lib.mapAttrs mkServices services;
    allServices = customServices // defaultServices;
  in {
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
          error-pages.errors = {
            status = "400-599";
            service = "error-pages";
            query = "/{status}.html";
          };
        };

        routers = allRouters;
        services = allServices;
      };
    };
  };

  # Add error pages
  virtualisation.oci-containers.containers = {
    error-pages = {
      autoStart = true;
      image = "ghcr.io/tarampampam/error-pages:3";
      environment = {
        TEMPLATE_NAME = "lost-in-space";
      };
      ports = [
        "127.0.0.1:8081:8080/tcp"
      ];
    };
  };
}
