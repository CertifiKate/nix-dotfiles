{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) user;
in {
  flake.modules.nixos."roles/physical/common/impermanence" = {
    config,
    lib,
    ...
  }: let
    identity = "/persist/identity";
  in {
    imports = [inputs.impermanence.nixosModules.impermanence];

    fileSystems = {
      "/" = {
        fsType = "tmpfs";
        options = ["mode=0755" "size=2G"];
      };
      "/disk" = {
        device = "/dev/disk/by-label/nixos";
        fsType = "ext4";
        neededForBoot = true;
      };
      "/nix" = {
        device = "/disk/nix";
        fsType = "none";
        options = ["bind"];
        neededForBoot = true;
      };
      "/persist" = {
        device = "/disk/persist";
        fsType = "none";
        options = ["bind"];
        neededForBoot = true;
      };
    };

    environment.persistence."/persist/data" = {
      hideMounts = true;
      directories = [
        "/var/log"
        # Auto-assigned uids must not drift
        "/var/lib/nixos"
        # Timer stamps, so persistent timers (ie. autoUpgrade) know what they missed
        "/var/lib/systemd/timers"
        "/var/lib/systemd/coredump"
        "/var/lib/systemd/backlight"
        "/etc/NetworkManager/system-connections"
        "/var/lib/NetworkManager"
        "/var/lib/bluetooth"
        "/var/lib/boltd" # Thunderbolt device authorisations
        "/var/lib/fwupd"
        "/var/lib/upower"
        "/var/lib/power-profiles-daemon"
        "/var/lib/AccountsService"
        "/var/lib/cups"
        {
          directory = "/home/${user}";
          user = user;
          group = "users";
          mode = "0700";
        }
      ];
    };

    sops.age.keyFile = lib.mkForce "${identity}/sops-age.txt";
    services.openssh.hostKeys = [
      {
        path = "${identity}/ssh_host_ed25519_key";
        type = "ed25519";
      }
    ];

    environment.etc.machine-id.text = "${builtins.hashString "md5" config.networking.hostName}\n";

    systemd.services.nix-daemon.environment.TMPDIR = "/nix/tmp";
    systemd.tmpfiles.rules = ["d /nix/tmp 0755 root root 1d"];
    security.sudo.extraConfig = "Defaults lecture=never";
  };
}
