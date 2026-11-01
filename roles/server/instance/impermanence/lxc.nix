#
# Impermanence for Incus LXC instances
#
# LXCs have no initrd, so the mounts have to be done from stage-2 activation, before anything uses
# the paths we mount over
#
{
  flake.modules.nixos."roles/server/instance/impermanence/lxc" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    cfg = config.CertifiKate.persist;
    data = path: "/persist/data${path}";
    persisted = cfg.directories ++ cfg.localDirectories;

    tmpfs = mode: size: {
      fsType = "tmpfs";
      options = ["mode=${mode}" "size=${size}"];
    };
    bind = src: {
      device = src;
      fsType = "none";
      options = ["bind"];
    };
  in {
    config = lib.mkIf (cfg.enable && cfg.backend == "lxc") {
      boot.specialFileSystems =
        {
          "/var" = tmpfs "0755" "256M";
          "/home" = tmpfs "0755" "64M";
          "/root" = tmpfs "0700" "64M";
          "/tmp" = tmpfs "1777" "256M";
          "/etc" = tmpfs "0755" "32M";
          "/bin" = tmpfs "0755" "1M";
          "/usr" = tmpfs "0755" "1M";

          # Self-binds, so that they stay writable once / isn't
          # rbind as stage-2 has already mounted /nix/store read-only, and a bind would hide that
          "/nix" = bind "/nix" // {options = ["rbind"];};
          "/persist" = bind "/persist";
        }
        // lib.genAttrs persisted (dir: bind (data dir));

      # Must run before specialfs, which has to be a plain string so can't be given deps. The
      # snippets run in name order, other than deps, so the 00 gets this to the front
      system.activationScripts."00-persist-prepare".text = ''
        # Reboots start out writable, but a switch can need new mountpoints on /
        mount -o remount,bind,rw /
        install -d -m 0700 /persist/identity
        mkdir -p ${toString (map data persisted ++ map (file: dirOf (data file)) cfg.files)}
      '';

      system.activationScripts.persist-files = lib.stringAfter ["specialfs"] (lib.concatMapStrings (file: ''
          mkdir -p ${dirOf file}
          ln -sfn ${data file} ${file}
        '')
        cfg.files);

      # specialfs would otherwise mount /bin over the top of it
      system.activationScripts.binsh.deps = ["specialfs"];

      # Can't be done from activation at boot, as stage-2 logs to a file on / until it starts systemd.
      # No RemainAfterExit, so that this runs again after the rw remount in a switch
      systemd.services.persist-readonly-root = {
        description = "Remount / read-only";
        unitConfig.DefaultDependencies = false;
        after = ["local-fs.target"];
        before = ["sysinit.target" "sysinit-reactivation.target"];
        wantedBy = ["sysinit.target"];
        requiredBy = ["sysinit-reactivation.target"];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.util-linux}/bin/mount -o remount,bind,ro /";
        };
      };

      # On a host's first deploy, specialfs would mount straight over the /etc and /var it's running from
      system.preSwitchChecks.impermanentRebooted = ''
        if { [ "$2" = switch ] || [ "$2" = test ]; } && ! ${pkgs.util-linux}/bin/mountpoint -q /etc; then
          echo "/etc isn't a tmpfs yet - deploy with 'boot' and reboot instead"
          exit 1
        fi
      '';

      # Only for nix-channel, which isn't used. It needs a sandbox, which LXCs don't have without
      # nesting, and a new /var/lib/nixos won't have the marker saying it's already been done
      system.installer.channel.enable = false;

      # Never rewritten once set, which is what lets deploys work with / read-only
      system.build.installBootLoader = lib.mkForce (pkgs.writeShellScript "install-lxc-sbin-init" ''
        target=/nix/var/nix/profiles/system/init
        if [ "$(${pkgs.coreutils}/bin/readlink /sbin/init)" != "$target" ]; then
          ${pkgs.coreutils}/bin/ln -sfn "$target" /sbin/init
        fi
      '');
    };
  };
}
