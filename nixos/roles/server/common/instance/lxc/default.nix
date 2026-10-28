{modulesPath, ...}: {
  imports = [
    ../default.nix
    "${modulesPath}/virtualisation/lxc-container.nix"
  ];
}
