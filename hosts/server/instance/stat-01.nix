{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.stat-01 = {
    deployment.tags = ["srv" "monitor"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/services/metrics-relay"
      ];

      networking.hostName = "stat-01";

      CertifiKate.metricsRelay.incusNode = "incus-01";

      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "10.10.0.21";
          prefixLength = 24;
        }
      ];
    };
  };
}
