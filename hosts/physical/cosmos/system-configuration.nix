{
  vars,
  lib,
  pkgs,
  ...
}: {
  # Set up system-specific configuration
  imports = [
    ../../../users/deploy_user.nix
  ];

  # It's just easier to do my deployments from my laptop, so gimme access!
  nix.settings.trusted-users = [
    "deploy_user"
  ];

  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/${vars.user}/source/nix-dotfiles";
  };

  services.openssh = {
    enable = true;
    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };

  # Wake on LAN
  # Let our HTPC wake it up for remote streaming
  networking = {
    interfaces.wlp6s0.wakeOnLan.enable = true;
    firewall = {
      allowedUDPPorts = [9];
    };
  };

  # Drivers for AMD
  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };
  hardware.amdgpu = {
    opencl.enable = true;
  };
  services.lact.enable = true;
  boot.kernelParams = [
    "video=DP-1:3440x1440@100"
    "video=HDMI-A-1:1920x1080@74.97"
  ];

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
