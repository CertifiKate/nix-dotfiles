{
  inputs,
  outputs,
  lib,
  config,
  pkgs,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  imports = [
    ./ssh-client
  ];

  # Configure our git config
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
  };
}
