{inputs, outputs, lib, config, pkgs, ...}:
let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  # Github private keys
  sops.secrets."kate_github_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519-github";
  };

  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
  };
}