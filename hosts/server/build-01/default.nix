{lib, ...}: {
  imports = [
    ../../../nixos/roles/server/deployment-host
    ../../../nixos/roles/server/nix-builder
  ];

  networking.hostName = "build-01";

  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/kate/nix-dotfiles";
  };
}
