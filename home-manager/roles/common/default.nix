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
    ../../modules/vscode
  ];

  # Github private keys
  # TODO: Persist the passphrase? Add to keyring?
  sops.secrets."kate_github_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519-github";
  };

  # Configure our git config
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
  };
}
