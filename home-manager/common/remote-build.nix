{
  lib,
  config,
  inputs,
  vars,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
  mkRemoteBuilderMatchBlock = hostname: {
    name = hostname;
    value = lib.hm.dag.entryBefore ["*"] {
      hostname = hostname;
      user = "nix-builder";
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_remote_build"
      ];
    };
  };
in {
  options.CertifiKate.remoteBuilders = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable remote builds using a builder machine";
    };
    buildHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      description = "List of hostnames to use as remote builders";
    };
  };
  config = lib.mkMerge [
    (lib.mkIf config.CertifiKate.remoteBuilders.enable {
      sops.secrets."remote_build_ssh_key" = {
        sopsFile = "${secretsPath}/secrets/shared.yaml";
        path = "/home/${vars.user}/.ssh/id_ed25519_remote_build";
      };
      programs.ssh.matchBlocks = lib.listToAttrs (
        map mkRemoteBuilderMatchBlock config.CertifiKate.remoteBuilders.buildHosts
      );
    })
  ];
}
