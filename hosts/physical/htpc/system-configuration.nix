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
    # Should only need wired connections
    networkmanager.enable = lib.mkForce false;
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

  hardware.enableRedistributableFirmware = true;
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
    extraPackages = with pkgs; [
      intel-media-driver
      intel-compute-runtime
      vpl-gpu-rt
    ];
  };

  services.xserver.enable = false;
  programs.xwayland.enable = false;

  services.pipewire = {
    enable = true;
    alsa.enable = true;
    pulse.enable = true;
  };

  # User needs these groups for /dev/dri access
  users.users.${vars.user}.extraGroups = ["video" "render" "input"];
}
