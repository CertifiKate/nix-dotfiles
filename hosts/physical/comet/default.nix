# === GPD Pocket 3 ===
{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) nixos homeManager;
in {
  configurations.nixos.comet.installer = {};

  configurations.nixos.comet.module = {
    imports = [
      ./_hardware-configuration.nix
      nixos."modules/profiles/physical"
      nixos."roles/physical/common/impermanence"

      nixos."roles/physical/desktop/cosmic"
      nixos."modules/network/wireguard"
    ];

    CertifiKate.wireguard.interfaces = ["Home"];

    home-manager.users.${user}.imports = [
      homeManager."modules/personal"
      homeManager."modules/personal/ssh-client"
    ];

    networking.hostName = "comet";
  };
}
