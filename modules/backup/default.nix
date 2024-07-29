{config, pkgs, lib, ...}:
let
  cfg = config.CertifiKate.backup_service;

in
{

  # TODO: Setup backup service
  # TODO: Setup timer that runs service on [interval]

  # TODO: Add scoping of paths?
  options.CertifiKate.backup_service = {
    paths = lib.mkOption {
      type = with lib; types.listOf types.path;
      default = [];
      description = "List of paths to backup";
    };
  };


  config = {
    # Add write-only backup key
    sops.secrets."backup_service_write_only_key" = {
      path = "/etc/ssh/backup_key";
    };

    # Install rsync to handle our copying of files
    environment.systemPackages = with pkgs; [
      rsync
    ];

    # Create our backup service
    systemd.services."backup_service" = let
      paths = "${lib.concatStringsSep " " cfg.paths}";

    in
    {
      # TODO: Add pre-start option (i.e dump db, stop service, etc)
      # TODO: Add post-stop options (i.e start service, etc.)

      script = ''
        rsync "${paths}" > /tmp/backup_files
      '';

      serviceConfig = {
        Type = "oneshot";
        # TODO: Set user?
      };
    };
  };

}