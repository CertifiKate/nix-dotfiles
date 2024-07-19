{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/virtualisation/proxmox-image.nix")
    ../../services/vs-code-server.nix
  ];
}