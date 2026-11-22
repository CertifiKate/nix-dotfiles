{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.comet.module = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      nixos."modules/users/deploy-user"
    ];

    nix.settings.trusted-users = ["deploy_user"];

    environment.variables = {
      NIX_FLAKE_PATH = lib.mkForce "/home/${user}/source/nix-dotfiles";
    };

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.timeout = 0;
    boot.loader.systemd-boot.configurationLimit = 10;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    systemd.services.NetworkManager-wait-online.enable = false;

    zramSwap.enable = true;

    services.tlp.enable = false;

    # Firmware lets the Pentium 7505 burst to 38W, which mostly just spins the fan up. Power profiles
    # come from system76-power (COSMIC's battery applet), which doesn't touch RAPL. Reapplied on resume too
    powerManagement.powerUpCommands = ''
      echo 20000000 > /sys/class/powercap/intel-rapl:0/constraint_1_power_limit_uw || true
    '';

    # The touchpad's firmware turns two-finger scrolls into wheel events, and sends horizontal backwards
    environment.etc."libinput/local-overrides.quirks".text = ''
      [GPD Pocket 3 Touchpad]
      MatchUdevType=mouse
      MatchBus=usb
      MatchVendor=0x258A
      MatchProduct=0x000C
      ModelInvertHorizontalScrolling=1
    '';

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };

    swapDevices = [
      {
        device = "/disk/swapfile";
        size = 16 * 1024;
        priority = 0;
      }
    ];

    boot.resumeDevice = "/dev/disk/by-label/nixos";
    boot.kernelParams = ["resume_offset=53125120"];

    systemd.sleep.settings.Sleep.HibernateDelaySec = "15min";
    services.upower.criticalPowerAction = "Hibernate";
    services.logind.settings.Login = {
      PowerKeyIgnoreInhibited = true;
      HandlePowerKey = "suspend-then-hibernate";
      HandleLidSwitch = "suspend-then-hibernate";
    };
  };
}
