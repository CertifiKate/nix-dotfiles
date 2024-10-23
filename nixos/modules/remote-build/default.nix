{
  lib,
  config,
  inputs,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  options.CertifiKate.useRemoteBuild = lib.mkOption {
    default = true;
  };

  config =
    # lib.mkIf config.CertifiKate.useRemoteBuild
    {
      nix = {
        distributedBuilds = true;
        settings = {
          builders-use-substitutes = true;
        };

        buildMachines = [
          {
            hostName = "builder";
            system = "x86_64-linux";
            protocol = "ssh-ng";
            # maxJobs = 2;
            # speedFactor = 2;
            sshUser = "nix-builder";
            sshKey = "/root/.ssh/id_ed25519_remote_build";
            supportedFeatures = ["nixos-test" "benchmark" "big-parallel" "kvm"];
            mandatoryFeatures = [];
          }
        ];
      };

      sops.secrets."remote_build_ssh_key" = {
        sopsFile = "${secretsPath}/secrets/shared.yaml";
        path = "/root/.ssh/id_ed25519_remote_build";
      };

      programs.ssh.extraConfig = ''
        Host builder
          HostName build-01.srv
          User nix-builder
          IdentityFile /root/.ssh/id_ed25519_remote_build
      '';
    };
}
