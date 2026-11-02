#
# Hosts are declared as `configurations.nixos.<name>` and turned into `nixosConfigurations`
# Any host with `deployment` set is also added to the colmena hive (see ./colmena.nix)
# Machines with only home-manager are declared as `configurations.home.<name>`, and turned into
# `homeConfigurations`
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

  options.configurations.home = lib.mkOption {
    type = lib.types.lazyAttrsOf (lib.types.submodule {
      options.module = lib.mkOption {
        type = lib.types.deferredModule;
        description = "The home-manager module for this machine";
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

  config.flake.homeConfigurations =
    lib.mapAttrs (
      name: {module, ...}:
        inputs.home-manager.lib.homeManagerConfiguration {
          pkgs = inputs.nixpkgs.legacyPackages.x86_64-linux;
          modules = [module];
        }
    )
    config.configurations.home;
}
