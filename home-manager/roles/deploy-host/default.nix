{
  vars,
  inputs,
  lib,
  pkgs,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
in {
  # Key used for colmena
  sops.secrets."deploy_ssh_key" = {
    sopsFile = "${secretsPath}/secrets/deploy.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_deploy";
  };

  sops.secrets."host_keys" = {
    sopsFile = "${secretsPath}/secrets/deploy.yaml";
    path = "/home/${vars.user}/.keys/deploy_keys.yaml";
  };

  programs.vscode = {
    profiles.default = {
      extensions = lib.mkBefore (with pkgs.vscode-extensions; [
        hashicorp.terraform
      ]);
    };
  };

  home.packages = [
    inputs.colmena.packages.${pkgs.system}.colmena
  ];

  programs.ssh.matchBlocks = {
    # Add the deploy key to all .srv hosts, which should be the ones we use colmena to manage
    "*.srv" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_deploy"
      ];
    };
    "*.infra" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_deploy"
      ];
    };
  };
}
