{pkgs, ...}:
{
  # Add rrsync to allow write-only backups to destination folders
  environment.systemPackages = with pkgs; [
    rrsync
  ];


  systemd = {
    tmpfiles.rules = [
      "d /var/backups/ backup backup"
    ];
  };

  # Create the write-only backup user
  users.groups.backup = {};

  users.users.backup = {
    isNormalUser = true;
    group = "backup";
    # TODO: Scope this by host?
    openssh.authorizedKeys.keys = [
      # Setup rrsync restricted authorized key
      "command=\"${pkgs.rrsync}/bin/rrsync -wo /var/backups/\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIutECanUS5l5Z5FeAzgH6vxijosLGkQlcwcd7JWhez backup_write_only"
    ];
  };

  # TODO: Add local (external drive) borg backup
  # TODO: Add remote borgbase backup
}