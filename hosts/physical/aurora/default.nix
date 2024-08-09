{
  config,
  pkgs,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
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
}
