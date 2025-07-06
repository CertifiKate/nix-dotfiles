{modulesPath, ...}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
  ];
  nixpkgs.system = "x86_64-linux";
}
