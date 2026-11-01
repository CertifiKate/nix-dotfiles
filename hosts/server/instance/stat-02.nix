{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.stat-02 = {
    deployment.tags = ["srv" "monitor"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/metrics-relay"
      ];

      networking.hostName = "stat-02";

      CertifiKate.metricsRelay.incusNode = "incus-02";

      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "10.10.0.22";
          prefixLength = 24;
        }
      ];
    };
  };
}
