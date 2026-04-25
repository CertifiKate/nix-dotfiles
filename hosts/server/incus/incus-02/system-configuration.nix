{lib, ...}: {
  # Anything machine specifc - mounting drives, etc.

  # Bootloader
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  networking.hostId = "cd6e6e04";
  system.stateVersion = lib.mkForce "25.11";
  networking.useNetworkd = lib.mkForce true;
  nixpkgs.system = "x86_64-linux";
}
