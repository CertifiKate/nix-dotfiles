{ config, lib, ... }:

{
  imports = [
    ../../../roles/lxcs
    ../../../services/traefik.nix
  ];
}