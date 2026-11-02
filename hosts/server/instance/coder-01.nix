{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.coder-01 = {
    deployment.tags = ["srv" "code"];

    module = {
      imports = [
        nixos."modules/profiles/server"
        nixos."roles/server/instance/lxc"
        nixos."roles/server/instance/impermanence"
        nixos."roles/server/services/coder"
      ];

      networking.hostName = "coder-01";

      # For the Incus API, as macvlan can't reach its host
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "10.10.0.30";
          prefixLength = 24;
        }
      ];
    };
  };
}
