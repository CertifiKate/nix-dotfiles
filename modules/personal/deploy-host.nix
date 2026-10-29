#
# Machine used to deploy the servers with colmena
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) secretsPath user;
in {
  flake.modules.homeManager."modules/personal/deploy-host" = {
    lib,
    pkgs,
    ...
  }: {
    # Key used for colmena
    sops.secrets."deploy_ssh_key" = {
      sopsFile = "${secretsPath}/secrets/deploy.yaml";
      path = "/home/${user}/.ssh/id_ed25519_deploy";
    };

    sops.secrets."host_keys" = {
      sopsFile = "${secretsPath}/secrets/deploy.yaml";
      path = "/home/${user}/.keys/deploy_keys.yaml";
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
      # mkAfter so personal keys (see ./ssh-client.nix) are still tried first
      "*.srv" = lib.hm.dag.entryBefore ["*"] {
        identityFile = lib.mkAfter [
          "/home/${user}/.ssh/id_ed25519_deploy"
        ];
      };
      "*.infra" = lib.hm.dag.entryBefore ["*"] {
        identityFile = lib.mkAfter [
          "/home/${user}/.ssh/id_ed25519_deploy"
        ];
      };
    };
  };
}
