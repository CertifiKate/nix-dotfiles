{modulesPath, ...}: {
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];
  nixpkgs.system = "x86_64-linux";
}
