# Currently unused - uncomment to build it again
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  # configurations.nixos.avahi-01.module = {
  #   imports = [
  #     nixos."modules/profiles/server"
  #     nixos."roles/server/instance/lxc"
  #     nixos."roles/server/services/mdns-repeater"
  #   ];
  #
  #   networking.hostName = "avahi-01";
  # };
}
