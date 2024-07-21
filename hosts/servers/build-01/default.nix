{ config, ... }:

{
  imports = [ 
    ../../../roles/lxcs
    ../../../services/traefik.nix
  ];

  networking.hostName = "build-01";
}