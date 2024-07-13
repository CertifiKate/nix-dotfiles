{ config, ... }:

{
  imports = [ 
    ../services/minecraft.nix
  ];

  config.networking.hostname = "mine-01";
}