{pkgs, inputs, private, ...}:
let 
  secretsPath = builtins.toString inputs.nix-secrets;

  remote_borg_repo = "${private.remote_borg_repo}";

  # The location where backups are dumped to then be sent off to actual backup solutions (i.e borg)
  backup_dump_path = "/var/backups/";
in
{

  sops.secrets."backup_append_key" = {
    sopsFile = "${secretsPath}/secrets/backup.yaml";
  };
  sops.secrets."backup_encryption_key" = {
    sopsFile = "${secretsPath}/secrets/backup.yaml";
  };


  # Add rrsync to allow write-only backups to destination folders
  environment.systemPackages = with pkgs; [
    rrsync
  ];


  systemd = {
    tmpfiles.rules = [
      "d ${backup_dump_path} backup backup"
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
      "command=\"${pkgs.rrsync}/bin/rrsync -wo ${backup_dump_path}\",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPIutECanUS5l5Z5FeAzgH6vxijosLGkQlcwcd7JWhez backup_write_only"
    ];
  };

  # TODO: Add local (external drive) borg backup

  # Setup remote borg backup
  services.borgbackup.jobs."servers_remote" = {
    repo = "${remote_borg_repo}";
    paths = "${backup_dump_path}";
    encryption.mode = "repokey-blake2";
    encryption.passCommand = "cat /run/secrets/backup_encryption_key";
    environment.BORG_RSH = "ssh -i /run/secrets/backup_append_key";
    compression = "auto,zstd";
    # TODO: Open issue about this not working?
    appendFailedSuffix = false;
    archiveBaseName = null;
    startAt = "*-*-* 5:00:00";
  };
}