#
# Machine used to deploy the servers with colmena
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) secretsPath user remoteBuilders;
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
      inputs.colmena.packages.${pkgs.stdenv.hostPlatform.system}.colmena
    ];

    # Separate blocks from the personal ones in ./ssh-client.nix (OpenSSH adds IdentityFile from
    # every matching block in order). Placed after them, and before the build hosts, so keys are
    # still tried in the same order
    programs.ssh.settings = {
      # Add the deploy key to all .srv hosts, which should be the ones we use colmena to manage
      deploy-srv = lib.hm.dag.entryBetween (["*"] ++ remoteBuilders) ["*.srv"] {
        header = "Host *.srv";
        IdentityFile = [
          "/home/${user}/.ssh/id_ed25519_deploy"
        ];
      };
      deploy-infra = lib.hm.dag.entryBetween (["*"] ++ remoteBuilders) ["*.infra"] {
        header = "Host *.infra";
        IdentityFile = [
          "/home/${user}/.ssh/id_ed25519_deploy"
        ];
      };
    };
  };
}
