{modulesPath, ...}: {
  imports = [
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];
  nixpkgs.system = "x86_64-linux";
}
