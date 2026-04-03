{modulesPath, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];
  networking.hostName = "incus-03";
  nixpkgs.system = "x86_64-linux";
}
