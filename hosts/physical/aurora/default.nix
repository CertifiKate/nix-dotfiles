{
  lib,
  user,
  pkgs,
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
  environment.systemPackages = [
    pkgs.dotnet-sdk_8
    pkgs.dotnetCorePackages.dotnet_8.runtime
    pkgs.dotnetCorePackages.dotnet_8.aspnetcore
    pkgs.dotnet-aspnetcore_8
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Enable fingerprint
  services.fprintd = {
    enable = true;
  };

  # Fix ethernet not being detected
  # boot.initrd.kernelModules = ["8821cu"];
  # boot.extraModulePackages = [config.boot.kernelPackages.rtl8821cu];

  # Use 6.11 kernel (or later) to fix microphone not being detected
  # https://www.reddit.com/r/NixOS/comments/1fzpkcg/thinkpad_e14_gen_6_amd_microphone_issues/
  boot.kernelPackages = pkgs.linuxPackages_6_11;

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
  networking.firewall.checkReversePath = false;

  # Add DisplayLink support
  # nix-prefetch-url --name displaylink-600.zip https://www.synaptics.com/sites/default/files/exe_files/2024-05/DisplayLink%20USB%20Graphics%20Software%20for%20Ubuntu6.0-EXE.zip                                       255 ↵
  services.xserver.videoDrivers = ["displaylink"];
}
