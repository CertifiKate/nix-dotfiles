{modulesPath, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];
  networking.hostName = "incus-01";
}
