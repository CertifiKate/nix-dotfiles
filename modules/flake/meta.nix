#
# Values shared by every module. Read them from the flake-parts `config` (ie. `config.meta.user`)
# instead of passing them through specialArgs
#
{
  inputs,
  lib,
  ...
}: {
  options.meta = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "kate";
      description = "The primary/default user";
    };
    secretsPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = toString inputs.nix-secrets;
      description = "Path to the nix-secrets repo";
    };
    private = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      readOnly = true;
      default = builtins.fromJSON (builtins.readFile "${toString inputs.nix-secrets}/private.json");
      description = "Non-secret but private values (domains, etc.)";
    };
    remoteBuilders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "build-01.srv"
        "build-02.srv"
      ];
      description = "Hostnames used as remote nix builders";
    };
  };
}
