{modulesPath, ...}: {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];
  networking.hostName = "incus-02";
  nixpkgs.system = "x86_64-linux";
}
