{ config, lib, pkgs, modulesPath, ... }:

{
  imports = [ 
    (modulesPath + "/virtualisation/proxmox-lxc.nix")
    ../../services/vs-code-server.nix
  ];
}