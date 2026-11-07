#
# Per-host sops file - nix-secrets/secrets/hosts/<hostname>.yaml
#
{config, ...}: let
  inherit (config.meta) secretsPath;
in {
  flake.modules.nixos."modules/secrets/host" = {
    config,
    lib,
    ...
  }: {
    options.CertifiKate.secrets.hostSopsFile = lib.mkOption {
      type = lib.types.str;
      default = "${secretsPath}/secrets/hosts/${config.networking.hostName}.yaml";
    };
  };
}
