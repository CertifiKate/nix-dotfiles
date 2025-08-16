{
  vars,
  lib,
  pkgs,
  ...
}: {
  # Set up system-specific configuration

  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/${vars.user}/source/nix-dotfiles";
  };

  # Drivers for Nvidia GPU
  hardware.graphics.enable = true;
  services.xserver.videoDrivers = [ "nvidia" ];
  hardware.nvidia.open = false;
  
  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
