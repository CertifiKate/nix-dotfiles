{
  pkgs,
  vars,
  inputs,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  environment.systemPackages = with pkgs; [
    colmena
  ];

  # Key used for colmena
  sops.secrets."deploy_ssh_key" = {
    sopsFile = "${secretsPath}/secrets/deploy.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_colmena_deploy";
    owner = vars.user;
  };
}
