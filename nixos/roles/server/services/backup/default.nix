{
  lib,
  config,
  ...
}: {
  imports = [
    ../../../../modules/backup/server
  ];
  # Simple wrapper to enable the backup server module to keep it consistent
  config = lib.mkIf config.CertifiKate.roles.server.backup.enable {
    CertifiKate.modules.backup_server.enable = true;
  };
}
