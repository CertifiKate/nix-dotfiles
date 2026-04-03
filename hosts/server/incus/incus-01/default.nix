{modulesPath, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];
  networking.hostName = "incus-01";
  nixpkgs.system = "x86_64-linux";
}
