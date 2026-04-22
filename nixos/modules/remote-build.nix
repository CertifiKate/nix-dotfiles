{
  lib,
  config,
  inputs,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;

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
      nix = {
        distributedBuilds = true;
        settings = {
          builders-use-substitutes = true;
        };
        buildMachines = map (host: mkRemoteBuilder {hostname = host;}) config.CertifiKate.remoteBuilders.buildHosts;
      };
      sops.secrets."remote_build_ssh_key" = {
        sopsFile = "${secretsPath}/secrets/shared.yaml";
        path = "/root/.ssh/id_ed25519_remote_build";
      };
      programs.ssh.extraConfig =
        lib.concatMapStrings
        (host: mkRemoteBuilderSSHConfig {hostname = host;})
        config.CertifiKate.remoteBuilders.buildHosts;
    })
  ];
}
