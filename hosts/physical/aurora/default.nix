# === Laptop ===
{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) nixos homeManager;
in {
  configurations.nixos.aurora.module = {
    imports = [
      ./_hardware-configuration.nix
      nixos."modules/profiles/physical"

      inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd

      nixos."roles/physical/desktop/gnome"
      nixos."roles/physical/desktop/gaming"
      nixos."roles/physical/desktop/cosmic"
      nixos."modules/secrets/sops-admin"
    ];

    home-manager = {
      users.${user} = {
        imports = [
          homeManager."modules/personal"
          homeManager."modules/personal/ansible-controller"
          homeManager."modules/personal/deploy-host"
          homeManager."modules/personal/rdp-client"
        ];
        CertifiKate.rdpClient.hosts = ["mgmt-01.srv"];
      };
    };

    networking.hostName = "aurora";
  };
}
