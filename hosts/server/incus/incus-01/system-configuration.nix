{lib, ...}: {
  # Anything machine specific - mounting drives, etc.

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "342fd173";
  system.stateVersion = lib.mkForce "25.11";
  networking.useNetworkd = lib.mkForce true;
  nixpkgs.system = "x86_64-linux";
}
