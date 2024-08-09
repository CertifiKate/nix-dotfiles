{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../default.nix
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable fingerprint
  services.fprintd = {
    enable = true;
  };

  # ==== Power Management ====
  # Set by default in Gnome
  services.power-profiles-daemon.enable = false;
  services.tlp = {
    enable = true;
  };

  # Setup hibernation
  swapDevices = [
    {
      device = "/var/lib/swapfile";
      size = 16 * 1024;
    }
  ];
  boot.resumeDevice = "/dev/nvme0n1p2";
  boot.kernelParams = [
    "resume_offset=13154304"
  ];
}
