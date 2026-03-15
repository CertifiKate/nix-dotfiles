{
  pkgs,
  inputs,
  lib,
  private,
  config,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";
  project_dir = "/services/proxy";
  config_dir = "${project_dir}/config";
  data_dir = "${project_dir}/data";
in {
  imports = [
    ./dashboard.nix
  ];

  config = lib.mkMerge [
    (
      lib.mkIf config.CertifiKate.roles.server.proxy.enable {
        environment.systemPackages = with pkgs; [
          traefik
        ];

        # Setup backup service
        CertifiKate.modules.backup_service = {
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
          # Transform simplified route definitions into full traefik routers
          mkRouter = name: cfg: {
            service = "${name}";
            rule = "Host(`${cfg.host}.${project_tld}`)";
            priority = "128";
            entryPoints = "webHttps";
            middlewares = [
              "error-pages@file"
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

          mkService = name: cfg: {
            loadBalancer = {servers = [{url = "${cfg.dest}";}];};
          };

          defaultRouters = {
            traefik = {
              service = "api@internal";
              rule = "Host(`traefik.${project_tld}`)";
              entryPoints = "webHttps";
              priority = "10";
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

          # Transform all route definitions to routers and services
          customRouters = lib.mapAttrs mkRouter config.CertifiKate.roles.server.routes;
          customServices = lib.mapAttrs mkService config.CertifiKate.roles.server.routes;

          # Merge with defaults
          allRouters = customRouters // defaultRouters;
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
    )
  ];
}
