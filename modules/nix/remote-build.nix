#
# Offload nix builds to the build-xx servers, for both the system (nixos) and the user (home-manager)
#
{config, ...}: let
  inherit (config.meta) secretsPath user remoteBuilders;

  options = lib: {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Whether to enable remote builds using a builder machine";
    };
    buildHosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = remoteBuilders;
      description = "List of hostnames to use as remote builders";
    };
  };
in {
  flake.modules.nixos."modules/nix/remote-build" = {
    lib,
    config,
    ...
  }: let
    cfg = config.CertifiKate.remoteBuilders;

    mkRemoteBuilder = {hostname}: {
      hostName = hostname;
      system = "x86_64-linux";
      protocol = "ssh-ng";
      sshUser = "nix-builder";
      sshKey = "/root/.ssh/id_ed25519_remote_build";
      supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
      mandatoryFeatures = [];
      maxJobs = 2;
    };

    mkRemoteBuilderSSHConfig = {hostname}: ''
      Host ${hostname}
        HostName ${hostname}
        User nix-builder
        IdentityFile /root/.ssh/id_ed25519_remote_build
    '';
  in {
    options.CertifiKate.remoteBuilders = options lib;

    config = lib.mkIf cfg.enable {
      nix = {
        distributedBuilds = true;
        settings = {
          builders-use-substitutes = true;
        };
        buildMachines = map (host: mkRemoteBuilder {hostname = host;}) cfg.buildHosts;
      };
      sops.secrets."remote_build_ssh_key" = {
        sopsFile = "${secretsPath}/secrets/shared.yaml";
        path = "/root/.ssh/id_ed25519_remote_build";
      };
      programs.ssh.extraConfig =
        lib.concatMapStrings
        (host: mkRemoteBuilderSSHConfig {hostname = host;})
        cfg.buildHosts;
    };
  };

  flake.modules.homeManager."modules/nix/remote-build" = {
    lib,
    config,
    ...
  }: let
    cfg = config.CertifiKate.remoteBuilders;

    mkRemoteBuilderMatchBlock = hostname: {
      name = hostname;
      value = lib.hm.dag.entryBefore ["*"] {
        hostname = hostname;
        user = "nix-builder";
        identityFile = [
          "/home/${user}/.ssh/id_ed25519_remote_build"
        ];
      };
    };
  in {
    options.CertifiKate.remoteBuilders = options lib;

    config = lib.mkIf cfg.enable {
      sops.secrets."remote_build_ssh_key" = {
        sopsFile = "${secretsPath}/secrets/shared.yaml";
        path = "/home/${user}/.ssh/id_ed25519_remote_build";
      };
      programs.ssh.matchBlocks = lib.listToAttrs (
        map mkRemoteBuilderMatchBlock cfg.buildHosts
      );
    };
  };
}
