{
  inputs,
  lib,
  config,
  ...
}: let
  deployable = lib.filterAttrs (_: host: host.deployment != null) config.configurations.nixos;
in {
  flake.colmenaHive = inputs.colmena.lib.makeHive (
    {
      meta = {
        # Tags must be used, we don't let it deploy to anything unless it's tagged
        allowApplyAll = false;

        nixpkgs = import inputs.nixpkgs {
          system = "x86_64-linux";
        };
      };
    }
    // lib.mapAttrs' (name: host:
      lib.nameValuePair "${name}.srv" {
        imports = [host.module];
        deployment = {
          targetUser = "deploy_user";
          inherit (host.deployment) tags;
        };
      })
    deployable
  );
}
