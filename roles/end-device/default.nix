{pkgs, inputs, ...}:

let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  # TODO: Add sops age admin key
  # TODO: Move this all to home manager?

  # TODO: Add all private keys?

  programs.git.config = {
    user.name = "CertifiKate";
    user.email = "131977850+CertifiKate@users.noreply.github.com";
  };

  # Github private keys
  sops.secrets."kate_github_key" = {
    owner = "kate";
    sopsFile = "${secretsPath}/secrets/endpoint.yaml";
    path = "/home/kate/.ssh/id_ed25519-github";
  };

  environment.systemPackages = with pkgs; [
    sops
    age
  ];
}