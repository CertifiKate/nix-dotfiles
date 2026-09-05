# ZFS snapshot replication for Incus nodes via sanoid/syncoid
{
  config,
  lib,
  inputs,
  ...
}: let
  cfg = config.CertifiKate.roles.server.incus_host.zfsReplication;
  secretsPath = toString inputs.nix-secrets;
in {
  options.CertifiKate.roles.server.incus_host.zfsReplication = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Enable ZFS snapshot replication via sanoid/syncoid";
    };
    sourcePool = lib.mkOption {
      type = lib.types.str;
      default = "zpool/incus";
      description = "ZFS dataset to snapshot and replicate";
    };
    targets = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Syncoid replication targets (e.g. ['syncoid@incus-02:zpool/incus-replica' 'syncoid@incus-03:zpool/incus-replica'])";
    };
    intervalMinutes = lib.mkOption {
      type = lib.types.int;
      default = 60;
      description = "How often to run syncoid replication (minutes)";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.syncoid_replica_key = {
      sopsFile = "${secretsPath}/secrets/incus.yaml";
      owner = "syncoid";
      mode = "0400";
    };

    # The syncoid module creates the syncoid user/group — we just extend it
    users.users.syncoid = {
      shell = "/bin/sh";
      # Peers authorise inbound replication with this key
      openssh.authorizedKeys.keys = [
        "no-pty,no-port-forwarding,no-x11-forwarding,no-agent-forwarding ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOyNKoNdWcy5uGMPZS0d1OLeWNGFXZmjmcLq58pPYB79 Incus syncoid replica"
      ];
    };

    services.sanoid = {
      enable = true;
      datasets.${cfg.sourcePool} = {
        recursive = true;
        autosnap = true;
        autoprune = true;
        hourly = 4;
        daily = 7;
        monthly = 0;
      };
      datasets."zpool/incus-replica" = {
        recursive = true;
        autosnap = false;
        autoprune = true;
        hourly = 4;
        daily = 7;
        monthly = 0;
      };
    };

    services.syncoid = {
      enable = true;
      user = "syncoid";
      sshKey = config.sops.secrets.syncoid_replica_key.path;
      commands = builtins.listToAttrs (lib.imap0 (i: target: {
          name = "${cfg.sourcePool}-target-${toString i}";
          value = {
            source = cfg.sourcePool;
            inherit target;
            recursive = true;
          };
        })
        cfg.targets);
    };

    systemd.services.syncoid-replica-setup = {
      description = "Create ZFS replica dataset and grant syncoid receive permissions";
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        User = "root";
      };
      script = ''
        if ! ${config.boot.zfs.package}/bin/zfs list zpool/incus-replica > /dev/null 2>&1; then
          ${config.boot.zfs.package}/bin/zfs create zpool/incus-replica
        fi
        ${config.boot.zfs.package}/bin/zfs allow syncoid \
          compression,create,destroy,mount,mountpoint,receive,rollback,snapdir,snapshot \
          zpool/incus-replica
      '';
    };

    systemd.timers.syncoid = {
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = "${toString cfg.intervalMinutes}min";
        RandomizedDelaySec = "300";
      };
    };
  };
}
