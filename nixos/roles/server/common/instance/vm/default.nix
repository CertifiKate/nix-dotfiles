{modulesPath, ...}: {
  imports = [
    ../default.nix
    "${modulesPath}/virtualisation/incus-virtual-machine.nix"
  ];
}
