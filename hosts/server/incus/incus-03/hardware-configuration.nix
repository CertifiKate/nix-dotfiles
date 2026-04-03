{modulesPath, ...}: {
  # Temporary - Proxmox VM for now!
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];
}
