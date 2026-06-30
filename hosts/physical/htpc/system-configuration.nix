{
  vars,
  lib,
  pkgs,
  ...
}: {
  imports = [
    ../../../users/deploy_user.nix
  ];

  # Set up our HTPC for remote management and deployment
  nix.settings.trusted-users = [
    "deploy_user"
  ];

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Wake on LAN
  networking = {
    networkmanager = {
      enable = true;
    };
    interfaces.eth0.wakeOnLan.enable = true;
    firewall = {
      allowedUDPPorts = [9];
    };
  };

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Intel NUC 6i7KYK - hardware specific configs
  # --- Intel i915 (Skylake Iris Pro 580) ---
  boot.initrd.kernelModules = ["i915"];
  boot.kernelModules = ["kvm-intel"];
  boot.kernelParams = [
    "i915.enable_guc=2"
    "i915.enable_fbc=1"
  ];

  hardware.cpu.intel.updateMicrocode = true;

  environment.variables = {
    LIBVA_DRIVER_NAME = "iHD";
    VDPAU_DRIVER = "va_gl";
  };

  services.thermald.enable = true;
  powerManagement = {
    enable = true;
    cpuFreqGovernor = "performance";
  };

  hardware.enableRedistributableFirmware = true;
  hardware.enableAllFirmware = true;

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-vaapi-driver
      libva-vdpau-driver
      libvdpau-va-gl
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
    ];
    extraPackages32 = with pkgs; [
      intel-vaapi-driver
      intel-media-driver
    ];
  };

  services.xserver.enable = false;
  programs.xwayland.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  users.users.${vars.user}.extraGroups = ["video" "render" "input"];
}
