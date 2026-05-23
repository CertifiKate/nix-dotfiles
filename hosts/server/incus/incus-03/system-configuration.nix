{
  lib,
  pkgs,
  ...
}: {
  # Anything machine specifc - mounting drives, etc.
  fileSystems."/mnt/diskp" = {
    device = "/dev/disk/by-uuid/a02df0f0-3ec5-44fe-8b9d-f6fca33a0080";
    fsType = "ext4";
  };

  fileSystems."/mnt/disk1" = {
    device = "/dev/disk/by-uuid/ac294b4d-a791-482e-b5c0-f64bc880c5da";
    fsType = "ext4";
  };

  fileSystems."/mnt/disk2" = {
    device = "/dev/disk/by-uuid/e9c94384-9dd0-46ae-84b2-0c2de223d648";
    fsType = "ext4";
  };

  fileSystems."/mnt/storage" = {
    device = "/mnt/disk1:/mnt/disk2";
    fsType = "fuse.mergerfs";
    options = [
      "defaults"
      "allow_other"
      "use_ino"
      "cache.files=partial"
      "dropcacheonclose=true"
      "category.create=mfs"
      "moveonenospc=true"
      "minfreespace=100G"
      "fsname=storage"
    ];
    depends = ["/mnt/disk1" "/mnt/disk2"];
  };
  environment.systemPackages = [pkgs.mergerfs];

  services.snapraid = {
    enable = true;
    parityFiles = ["/mnt/diskp/snapraid.parity"];
    contentFiles = [
      "/var/snapraid/snapraid.content"
      "/mnt/disk1/snapraid.content"
      "/mnt/disk2/snapraid.content"
    ];
    dataDisks = {
      d1 = "/mnt/disk1/";
      d2 = "/mnt/disk2/";
    };
    sync.interval = "02:00";
    scrub = {
      interval = "Mon *-*-* 04:00:00";
      plan = 8;
      olderThan = 10;
    };
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "49fd2478";
  system.stateVersion = lib.mkForce "25.11";
  networking.useNetworkd = lib.mkForce true;
  nixpkgs.system = "x86_64-linux";
}
