{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    authelia
  ];

  networking.firewall.allowedTCPPorts = [ 9091 ];

  # TODO: Still got to find a better way to do this
  systemd.services.authelia-main = {
    environment = {
      AUTHELIA_JWT_SECRET = "{{ vault_authelia_jwt_secret }}";
      AUTHELIA_SESSION_SECRET = "{{ vault_authelia_session_secret }}";
      AUTHELIA_STORAGE_ENCRYPTION_KEY = "{{ vault_authelia_storage_key }}";
    };
  };

  services.authelia.instances.main = {
    enable = true;

    secrets.manual = true;
    settings = {
      session.domain = "{{ project_tld }}";

      authentication_backend.file.path = "/config/authelia-main/user-database.yml";

      #authentication_backend.file.path = "{{ config_dir }}/user-database.yml";

      storage.local.path = "/config/authelia-main/db.sqlite3";
      # storage.local.path = "{{ data_dir }}/db.sqlite3";
      
      access_control = {
        default_policy = "bypass";
        rules = [
          {
            domain = "auth.{{ project_tld }}";
            policy = "bypass";
          }
          {
            domain = "traefik.{{ project_tld }}";
            policy = "one_factor";
          }
        ];
      };

      notifier.filesystem.filename = "/config/authelia-main/notifier.txt";

    };
  };
}