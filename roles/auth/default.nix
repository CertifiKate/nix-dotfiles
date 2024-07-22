{ pkgs, inputs, config, lib, private, ... }:

let
  secretsPath = builtins.toString inputs.nix-secrets;

  project_tld = "${private.project_tld}";

  # TODO: Add a global config option for the storage directory
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
      "d ${config_dir} 700 authelia authelia"
      "d ${data_dir} 700 authelia authelia"
    ];
  };

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
  sops.secrets."authelia_users_database" = { 
    owner = "authelia";
    sopsFile = "${secretsPath}/secrets/authelia.yaml"; 
    path = "${config_dir}/user-database.yml";
  };

  users = {
    groups.authelia = {};
    users.authelia = {
      isSystemUser = true;
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
      server = {
        host = "0.0.0.0";
      };

      session.domain = "${project_tld}";

      authentication_backend.file.path = "${config_dir}/user-database.yml";
      # TODO: Move this to an actual db - add full-blown db server?
      storage.local.path = "${config_dir}/db.sqlite3";
      notifier.filesystem.filename = "${data_dir}/notifier.txt";

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