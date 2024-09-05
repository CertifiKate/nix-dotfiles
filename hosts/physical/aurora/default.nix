{
  config,
  lib,
  user,
  ...
}: {
  imports = [
    ./hardware-configuration.nix
    ../default.nix
  ];

  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/${user}/source/nix-dotfiles";
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable fingerprint
  services.fprintd = {
    enable = true;
  };

  # Fix ethernet not being detected
  boot.initrd.kernelModules = ["8821cu"];
  boot.extraModulePackages = [config.boot.kernelPackages.rtl8821cu];

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
  systemd.sleep.extraConfig = "HibernateDelaySec=4h";
}
