{pkgs, inputs, ...}:
# TODO: Rename this
let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  # TODO: Add all private keys?
  # TODO: Add ssh-agent forwarding

  # Github private keys
  sops.secrets."kate_github_key" = {
    owner = "kate";
    sopsFile = "${secretsPath}/secrets/endpoint.yaml";
    path = "/home/kate/.ssh/id_ed25519-github";
  };
}