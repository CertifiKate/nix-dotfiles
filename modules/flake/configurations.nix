#
# Hosts are declared as `configurations.nixos.<name>` and turned into `nixosConfigurations`
# Any host with `deployment` set is also added to the colmena hive (see ./colmena.nix)
#
{
  inputs,
  lib,
  config,
  ...
}: {
  options.configurations.nixos = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options = {
        module = lib.mkOption {
          type = lib.types.deferredModule;
          description = "The NixOS module for this host";
        };
        deployment = lib.mkOption {
          type = lib.types.nullOr (lib.types.submodule {
            options.tags = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              default = [];
              description = "Colmena tags for this host";
            };
          });
          default = null;
          description = "Colmena deployment settings. Hosts without this aren't deployed by colmena";
        };
      };
    });
    default = {};
  };

  config.flake.nixosConfigurations =
    lib.mapAttrs (
      name: {module, ...}:
        inputs.nixpkgs.lib.nixosSystem {
          modules = [module];
        }
    )
    config.configurations.nixos;
}
