#
# Instance which only keeps /nix and /persist across reboots
#
# Import alongside roles/server/instance/lxc or vm, which decides the backend used. Both have to be
# imported here as imports can't depend on config, so each one checks the backend itself
#
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."roles/server/instance/impermanence" = {config, ...}: {
    imports = [
      nixos."roles/server/instance/impermanence/lxc"
      nixos."roles/server/instance/impermanence/vm"
    ];

    CertifiKate.persist.enable = true;

    assertions = [
      {
        assertion = config.CertifiKate.persist.backend != null;
        message = "impermanence needs roles/server/instance/lxc or vm to be imported as well";
      }
    ];
  };
}
