{ config, lib, ... }:

{
  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/kate/nix-dotfiles";
  };

}