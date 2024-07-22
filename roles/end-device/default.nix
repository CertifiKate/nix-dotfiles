{pkgs, inputs, ...}:

let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{
  # TODO: Add git read/write private key
  # TODO: Add sops age admin key
  # TODO: Move this to home manager?

  # TODO: Add all private keys?

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