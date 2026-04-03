{modulesPath, ...}: {
  # Temporary - Proxmox VM for now!
  imports = [
    (modulesPath + "/virtualisation/proxmox-image.nix")
  ];

  networking.hostName = "incus-01";
}
