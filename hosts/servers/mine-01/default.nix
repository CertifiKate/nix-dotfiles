{ config, ... }:

{
  imports = [ 
    ../../../roles/lxcs
    ../../../services/minecraft.nix
  ];
}