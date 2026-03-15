{lib, ...}: {
  CertifiKate.roles.server.deployment_host.enable = true;
  CertifiKate.roles.server.nix_builder.enable = true;

  networking.hostName = "build-01";

  # Overwrite the path used for our shorthand aliases/functions
  environment.variables = {
    NIX_FLAKE_PATH = lib.mkForce "/home/kate/nix-dotfiles";
  };
}
