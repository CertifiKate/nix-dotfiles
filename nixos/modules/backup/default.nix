{config, pkgs, lib, ...}:
let
  cfg = config.CertifiKate.backup_service;

  backup_user = "backup";
  backup_host = "backup-01.srv";
in
{
  # TODO: Add scoping of paths?
  options.CertifiKate.backup_service = {
    paths = lib.mkOption {
      type = with lib; types.listOf types.path;
      default = [];
      description = "List of paths to backup";
    };
  };


  # Only configure if we have actually defined some paths
  config = lib.mkIf (cfg.paths != []) {

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
        ${pkgs.rsync}/bin/rsync -rptgoRL --delete ${paths} ${backup_user}@${backup_host}:$(cat /etc/hostname) -e "${pkgs.openssh}/bin/ssh -o StrictHostKeyChecking=no -i /etc/ssh/backup_key"
      '';

      serviceConfig = {
        Type = "oneshot";
        # TODO: Set user?
      };
    };

    systemd.timers."backup" = {
      wantedBy = [ "timers.target" ];
        timerConfig = {
          OnBootSec = "5m";
          OnUnitActiveSec = "5m";
          OnCalendar = "*-*-* 4:00:00";
          Unit = "backup_service.service";
        };
    };
  };
}