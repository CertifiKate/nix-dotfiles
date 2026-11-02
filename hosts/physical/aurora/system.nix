{config, ...}: let
  inherit (config.meta) user;
in {
  configurations.nixos.aurora.module = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # Set up system-specific configuration
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

    boot.kernelPackages = pkgs.linuxPackages_latest;

    hardware.enableRedistributableFirmware = true;

    boot.initrd.kernelModules = ["r8169"];

    # Disable autosuspend on btusb; load WiFi driver before Bluetooth to fix MT7922 init order
    boot.extraModprobeConfig = ''
      options btusb enable_autosuspend=0
      softdep btusb pre: mt7921e
    '';

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
    systemd.sleep.settings.Sleep = {
      HibernateDelaySec = "30min";
    };

    # Shrink the hibernation image as far as possible. With the default (2/5 of RAM)
    # amdgpu evicting VRAM during freeze leaves too little free RAM to build the image
    # ("Error -12 creating image").
    systemd.tmpfiles.rules = [
      "w /sys/power/image_size - - - - 0"
    ];

    systemd.services.systemd-suspend.serviceConfig.ExecStart = [
      ""
      "${config.systemd.package}/lib/systemd/systemd-sleep suspend-then-hibernate"
    ];
    services.logind.settings.Login = {
      HandleLidSwitch = "suspend-then-hibernate";
    };
    networking.firewall.checkReversePath = false;

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
    services.blueman.enable = true;
  };
}
