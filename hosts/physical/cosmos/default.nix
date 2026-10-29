# === Desktop ===
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.cosmos.module = {
    imports = [
      ./_hardware-configuration.nix
      nixos."modules/profiles/physical"

      nixos."roles/physical/desktop/gnome"
      nixos."roles/physical/desktop/gaming"
    ];

    # Most of the time I'm using this machine as a gaming desktop, so auto start in steam big picture
    CertifiKate.gaming.autoStartSteam = true;

    networking.hostName = "cosmos";
  };
}
