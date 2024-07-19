{ config, ... }:

{
  imports = [ 
    ../../../roles/lxcs
    ../../../services/traefik.nix
  ];

}