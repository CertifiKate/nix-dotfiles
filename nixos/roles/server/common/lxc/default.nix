{modulesPath, ...}: {
  imports = [
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];
  nixpkgs.system = "x86_64-linux";
}
