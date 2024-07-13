{ config, lib, ... }:

{
  imports = lib.concatMap import [ 
    ../services/traefik.nix
  ];

  config.networking.hostname = "auth-01";
}