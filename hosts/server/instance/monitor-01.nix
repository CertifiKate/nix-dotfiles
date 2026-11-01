{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.monitor-01 = {
    deployment.tags = ["srv" "monitor"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/monitoring"
      ];

      networking.hostName = "monitor-01";

      # Static IP on eth1 (net-infra bridge) to reach Incus metrics
      networking.interfaces.eth1 = {
        ipv4.addresses = [
          {
            address = "10.10.0.10";
            prefixLength = 24;
          }
        ];
      };
    };
  };
}
