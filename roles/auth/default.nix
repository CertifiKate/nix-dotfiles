{ pkgs, inputs, config, lib, ... }:

let
  secretsPath = builtins.toString inputs.nix-secrets;

  # TODO: Work out this
  project_tld = "test.example";

  project_dir = "/services/authelia";
  config_dir = "${project_dir}/config";
  data_dir = "${project_dir}/data";

in
{
  environment.systemPackages = with pkgs; [
    authelia
  ];

  networking.firewall.allowedTCPPorts = [ 9091 ];

  # Allow traefik to access config data dir
  systemd = {
    tmpfiles.rules = [
      # Allow anyone to access the base directory
      # "d ${project_dir} 777 root root"
      "d ${config_dir} 750 authelia authelia"
      "d ${data_dir} 750 authelia authelia"
    ];
  };

  sops.secrets."project_tld" = {};
  sops.secrets."authelia_jwt_secret" = { 
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authelia.yaml"; 
  };
  sops.secrets."authelia_session_secret" = { 
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authelia.yaml"; 
  };
  sops.secrets."authelia_storage_key" = { 
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authelia.yaml"; 
  };

  users = {
    groups.authelia = {};
    users.authelia = {
      # isSystemUser = true;
      isNormalUser = true;
      group = "authelia";
    };
  };

  # This was super fun to find buried in the service config after two hours debugging.
  systemd.services."authelia-main".serviceConfig.ProtectSystem = lib.mkForce false;
  
  services.authelia.instances.main = {
    user = "authelia";
    group = "authelia";
    enable = true;

    secrets = {
      jwtSecretFile = config.sops.secrets."authelia_jwt_secret".path;
      storageEncryptionKeyFile = config.sops.secrets."authelia_storage_key".path;
    };

    settings =  {
      session.domain = "${project_tld}";

      authentication_backend.file.path = "${config_dir}/user-database.yml";
      storage.local.path = "${config_dir}/db.sqlite3";
      notifier.filesystem.filename = "${data_dir}/notifier.txt";


      # authentication_backend.file.path = "/var/lib/authelia-main/users_database.yml";
      # notifier.filesystem.filename = "/var/lib/authelia-main/notification.txt";
      # storage.local.path = "/var/lib/authelia-main/db.sqlite3";

      access_control = {
        default_policy = "bypass";
        rules = [
          {
            domain = "auth.${project_tld}";
            policy = "bypass";
          }
          {
            domain = "traefik.${project_tld}";
            policy = "one_factor";
          }
        ];
      };


    };
  };
}