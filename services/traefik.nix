{ pkgs, ... }:

let 
  project_dir = "/services";
  config_dir = "${project_directory}/config";
  data_dir = "${project_dir}/data";

in {
  environment.systemPackages = with pkgs; [
    traefik
  ];

  networking.firewall.allowedTCPPorts = [ 80 443 ];

  # TODO: Use something more secure. Like. Anything else
  systemd.services.traefik = {
    environment = {
      CLOUDFLARE_DNS_API_TOKEN = "{{ vault_cloudflare_api_token }}";
    };
  };

  # Allow traefik to access config data dir
  systemd = {
    tmpfiles.rules = [
      # Allow anyone to access the base directory
      "d ${project_directory} 777 root root"
      "d ${config_dir} 1750 traefik traefik"
      "d ${data_dir} 1750 traefik traefik"
    ];
  };

  # TODO: Look into the Nix way of generating this config rather than ansible templating

  services.traefik = {
    enable = true;
    dataDir = "${data_dir}";
    staticConfigOptions = {
      entryPoints = {
        web = {
          address = ":80";
          http.redirections = {
            entryPoint = {
              to = "webHttps";
              scheme = "https";
              permanent = false;
            };
          };
        };
        webHttps.address = ":443";
      };

      api = {
        dashboard = true;
      };

      certificatesResolvers.letsEncrypt.acme = {
        email = "{{ vault_cloudflare_email }}";
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
          # TODO: Move to authelia
          authentikProxyAuth.forwardAuth = {
            address = "https://{{ hostvars["auth-01"].ansible_host }}:9443/outpost.goauthentik.io/auth/traefik";
            trustForwardHeader = "true";
            authResponseHeaders = [
              "X-authentik-username"
              "X-authentik-groups"
              "X-authentik-email"
              "X-authentik-name"
              "X-authentik-uid"
              "X-authentik-jwt"
              "X-authentik-meta-jwks"
              "X-authentik-meta-outpost"
              "X-authentik-meta-provider"
              "X-authentik-meta-app"
              "X-authentik-meta-version"
            ];

          };
        };
        routers = {
          authentik = {
            rule = "PathPrefix(`/outpost.goauthentik.io/`)";
            priority = "50";
            entryPoints = "webHttps";
            service = "service-authentik";
            tls = {
              certResolver = "letsEncrypt";
              domains = [
                {
                  main = "{{ project_tld }}";
                  sans = [
                    "*.{{ project_tld}}"
                  ];
                }
              ];
            };
          };

          traefik = {
            rule = "Host(`{{ project_tld }}`)";
            entryPoints = "webHttps";
            service = "api@internal";
            middlewares = [
              "authentikProxyAuth"
            ];
            tls = {
              certResolver = "letsEncrypt";
              domains = [
                {
                  main = "{{ project_tld }}";
                  sans = [
                    "*.{{ project_tld}}"
                  ];
                }
              ];
            };
          };

          {% for service in traefikServices %}

          router-{{ service.name }} = {
            service = "service-{{ service.name }}";
            {% if service.rule is defined %}
            rule = "{{ service.rule }}";
            {% else %}
            rule = "Host(`{{service.host}}`)";
            {% endif%}
            entryPoints = "webHttps";
            priority = "{{ service.priority | default(10) }}";
            {# {% if service.proxyAuth is undefined or service.proxyAuth %}
             middlewares = [
               "authentikProxyAuth"
             ];
             {% endif %} #}
            tls = {
              certResolver = "letsEncrypt";
              domains = [
                {
                  main = "{{ project_tld }}";
                  sans = [
                    "*.{{ project_tld}}"
                  ];
                }
              ];
            };
          };
          {% endfor %}
        };
        
        {% for service in traefikServices %}
        
        services = {
          service-{{ service.name}} = {
            loadBalancer = {
              servers = [
                {
                  url = "{{ service.destScheme }}://{{ hostvars[service.destHost].ansible_host }}:{{service.destPort}}";
                }
              ];
            };
          };
        };

        {% endfor %}
      };
    };
  };
}