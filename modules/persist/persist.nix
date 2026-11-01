#
# What a host needs to keep. Service roles list their state here, regardless of whether the host is
# impermanent - roles/server/instance/impermanence decides how it's kept
#
{config, ...}: let
  inherit (config.meta) user;
in {
  flake.modules.nixos."modules/persist" = {
    config,
    lib,
    ...
  }: let
    cfg = config.CertifiKate.persist;
    identity = "/persist/identity";

    persisted = cfg.directories ++ cfg.localDirectories;
    nested = lib.filter (a: lib.any (b: lib.hasPrefix "${b}/" a) persisted) persisted;
  in {
    options.CertifiKate.persist = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = false; # false = not impermanent; paths are just normal dirs
        description = "Set by the impermanence role; never set directly by hosts or services";
      };
      backend = lib.mkOption {
        type = lib.types.nullOr (lib.types.enum ["lxc" "vm"]);
        default = null;
        description = "Set by the instance role; never set directly by hosts or services";
      };
      directories = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Absolute paths of state that must survive reboot (and be backed up)";
      };
      files = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        description = "Absolute paths of single files that must survive reboot (and be backed up)";
      };
      localDirectories = lib.mkOption {
        type = with lib.types; listOf str;
        default = [];
        internal = true;
        description = "Directories that survive reboot but aren't backed up or restored into clones";
      };
    };

    config = lib.mkMerge [
      {
        # The real paths rather than /persist/data, so backups look the same on any kind of host
        CertifiKate.backup.paths = cfg.directories ++ cfg.files;
      }

      (lib.mkIf cfg.enable {
        assertions = [
          {
            assertion = nested == [];
            message = "CertifiKate.persist can't have nested paths, as bind order gets fiddly: ${toString nested}";
          }
        ];

        CertifiKate.persist = {
          # Auto-assigned uids must not drift, or the ownership of everything persisted breaks
          directories = ["/var/lib/nixos"];
          # The whole of home, as zsh replaces its history file so it can't be linked on its own.
          # Images can be pulled again, so don't need backing up, but won't fit on the /var tmpfs
          localDirectories =
            ["/var/log" "/home/${user}"]
            ++ lib.optional (config.virtualisation.oci-containers.containers != {}) "/var/lib/containers";
        };

        # The bind source is created by root, and being there stops the user's home being set up
        systemd.tmpfiles.rules = ["d /home/${user} 0700 ${user} users -"];

        # Host identity is never backed up, so that clones can't inherit it
        sops.age.keyFile = lib.mkForce "${identity}/sops-age.txt";
        services.openssh.hostKeys = [
          {
            path = "${identity}/ssh_host_ed25519_key";
            type = "ed25519";
          }
        ];

        # Derived rather than persisted so clones differ automatically. The journal directory is
        # named after this, so it has to stay the same between boots
        environment.etc.machine-id.text = "${builtins.hashString "md5" config.networking.hostName}\n";
      })
    ];
  };
}
