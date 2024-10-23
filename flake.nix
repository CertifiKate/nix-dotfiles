{
  inputs = {
    # I want to use unstable by default but for some things use stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-24.05";

    sops-nix.url = "github:Mic92/sops-nix";

    nix-colors.url = "github:Misterio77/nix-colors";

    nix-secrets = {
      url = "git+ssh://git@github.com/CertifiKate/nix-secrets.git";
      flake = false;
    };

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs-stable";
    };

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";

    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
  };

  outputs = {
    self,
    nixpkgs,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;

    commonInherits = {
      inherit (nixpkgs) lib;
      inherit inputs outputs nixpkgs home-manager;
    };

    # Set the primary/default user. Can be overwritten on a system level
    user = "kate";

    systems = {
      physical = {
        # Lenovo Thinkpad E14 Gen 6 (AMD)
        aurora = {
          systemType = "physical";
          roles = [
            /physical/desktop/gnome
            /physical/desktop/sway
            /server/deployment-host
          ];
          hmRoles = [
            /desktop/gnome
            /desktop/sway
            /sops-management
            /ansible-controller
          ];
          extraModules = [
            # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd
          ];
        };

        # Acer Swift 3 SF353-51
        swift3 = {
          systemType = "physical";
          roles = [
            /physical/desktop/gnome
            /physical/desktop/sway
          ];
          hmRoles = [
            /desktop/gnome
            /desktop/sway
            /sops-management
            /ansible-controller
          ];
        };
      };

      server = {
        # ==== LXCs ====================
        build-01 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/deployment-host
            /server/nix-builder
          ];
          colmenaConfig = {
            targetHost = "build-01.srv";
            tags = ["build"];
          };
          extraModules = [
            # inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd
            {CertifiKate.useRemoteBuild = false;}
          ];
        };

        auth-01 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/auth
          ];
          colmenaConfig = {
            targetHost = "auth-01.srv";
            tags = ["core" "auth"];
          };
        };

        prox-01 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/proxy
          ];
          colmenaConfig = {
            targetHost = "prox-01.srv";
            tags = ["core" "proxy"];
          };
        };

        avahi-01 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/mdns-repeater
          ];
          colmenaConfig = {
            targetHost = "avahi-01.srv";
            tags = ["avahi"];
          };
        };

        media-01 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/common/media_server
            /server/jellyfin
          ];
          colmenaConfig = {
            targetHost = "media-01.srv";
            tags = ["media"];
          };
        };

        media-02 = {
          systemType = "server";
          serverType = "lxc";
          roles = [
            /server/common/media_server
            /server/media_dl
          ];
          colmenaConfig = {
            targetHost = "media-02.srv";
            tags = ["media"];
          };
        };

        # ==== VMs =====================
        backup-01 = {
          systemType = "server";
          serverType = "vm";
          extraModules = [
            ./nixos/modules/backup/server
          ];
          colmenaConfig = {
            targetHost = "backup-01.srv";
            tags = ["core" "backup"];
          };
        };

        mine-01 = {
          systemType = "server";
          serverType = "vm";
          roles = [
            /server/minecraft
          ];
          colmenaConfig = {
            targetHost = "mine-01.dmz";
            tags = ["minecraft"];
          };
        };
        # ==============================
      };
    };

    mkSystem = host: system:
      import ./hosts.nix (commonInherits
        // {
          hostName = "${host}";
          user = system.user or user;
          serverType = system.serverType or null;
        }
        // system);
  in {
    serverConfigs = nixpkgs.lib.mapAttrs mkSystem (systems.server);
    physicalConfigs = nixpkgs.lib.mapAttrs mkSystem (systems.physical);

    # Collection of all of our configs
    nixosConfigurations = self.physicalConfigs // self.serverConfigs;

    colmena =
      {
        meta = {
          nixpkgs = import inputs.nixpkgs {system = "x86_64-linux";};
          # nodeNixpkgs = builtins.mapAttrs (_: v: v.pkgs) self.nixosConfigurations;
          nodeSpecialArgs = builtins.mapAttrs (_: v: v._module.specialArgs) self.serverConfigs;
        };
      }
      // builtins.mapAttrs (_: v: {
        deployment =
          v._module.specialArgs.colmenaConfig
          // {
            targetUser = "deploy_user";
            # TODO: Not supported in 0.4, use ssh agent as a bandaid because I don't have time to deal with updating
            # sshOptions = [
            #   "-i ~/.ssh/id_ed25519_colmena_deploy"
            # ];
          };
        imports = v._module.args.modules;
      })
      self.serverConfigs;
  };
}
