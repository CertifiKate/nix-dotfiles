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

    home-manager.url = "github:nix-community/home-manager";
    home-manager.inputs.nixpkgs.follows = "nixpkgs-stable";

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  # Based on https://www.reddit.com/r/NixOS/comments/yk4n8d/comment/iurkkxv
  outputs = {
    self,
    nixpkgs,
    nixpkgs-stable,
    sops-nix,
    nix-colors,
    home-manager,
    ...
  } @ inputs: let
    inherit (self) outputs;

    # ==============================
    # NixOs Configuration
    # ==============================

    # Basic configuration modules
    commonModules = name: cfg: [
      # Set common config options
      {
        nix.settings.experimental-features = ["nix-command" "flakes"];
        networking.hostName = name;
      }

      # Include our host config
      ./hosts/${(cfg.hostType or "servers")}/${name}

      # Absolute minimum config required
      ./base.nix
      # Include our shared configuration
      ./nixos/roles/common

      sops-nix.nixosModules.sops
    ];

    # Server Modules
    serverModules = name: cfg: [
      ./nixos/roles/server
      ./nixos/roles/server/${cfg.serverType or "lxc"}
      ./nixos/modules/backup
    ];

    physicalDeviceModules = name: cfg: [
      ./nixos/roles/physical
    ];

    # ==============================
    # Home-Manager Configuration
    # ==============================

    # Common home-manager options (I /think/ this should be nixos neutral, but I currently only use nixos)
    mkHomeManagerModules = cfg: [
      {
        home-manager.users.kate.imports =
          [
            ./home.nix
            ./home-manager/roles/common
          ]
          ++ (cfg.hmRoles or []);
      }
      # Add sops age-key to use for home-manager to decrypt sops secrets (without needing to add it ourselves)
      {
        # TODO: Vars for user
        sops.secrets."home_manager_user_key" = {
          sopsFile = "${builtins.toString inputs.nix-secrets}/secrets/home-manager-init.yaml";
          path = "/home/kate/.config/sops-age.txt";
          owner = "kate";
        };
      }
    ];

    # NixOs specific home-manager modules
    mkNixOsHomeManagerModules = cfg:
      [
        home-manager.nixosModules.home-manager
        {
          # TOOD: Add user into this inherit -let it be used by home-manager
          home-manager.extraSpecialArgs = {
            inherit inputs nix-colors;
          };
          home-manager.useGlobalPkgs = true;
          home-manager.useUserPackages = true;
          home-manager.users.kate.imports = [
            inputs.sops-nix.homeManagerModules.sops
          ];
        }
      ]
      ++ mkHomeManagerModules cfg;

    # ==============================
    # NixOs Config Generation
    #
    # Uses above configs to generate the nixos systems
    # Uses systems var to populate
    # ==============================

    # Generates the relevant system configuration based on inputs
    mkNixosSystem = name: cfg:
      nixpkgs.lib.nixosSystem {
        system = cfg.system or "x86_64-linux";

        # Include our common modules, plus any host specified roles
        modules =
          (commonModules name cfg)
          ++ (cfg.roles or [])
          ++
          # If the hostType is servers then add in our serverModules
          nixpkgs.lib.optionals (cfg.hostType == "servers") (serverModules name cfg)
          ++
          # If the hostType is physical then add in our physicalDeviceModules
          nixpkgs.lib.optionals (cfg.hostType == "physical") (physicalDeviceModules name cfg)
          ++
          # Include HomeManager (opt in for servers, opt out otherwise)
          nixpkgs.lib.optionals ((cfg.hostType == "servers" && (cfg.usesHomeManager or false)) || (cfg.hostType != "servers" && cfg.usesHomeManager or true)) (mkNixOsHomeManagerModules cfg);

        specialArgs = {
          inherit inputs;

          # A .json file from the nix-secrets repo with non-important info.
          # Stuff we just don't want public (ie. project_tld) but don't care if it's in the nix store
          private = builtins.fromJSON (builtins.readFile "${builtins.toString inputs.nix-secrets}/private.json");
        };
      };

    # NixOS System definitions
    # If hostType = server then home-manager is opt-in, otherwise opt-out
    systems = {
      swift3 = {
        hostType = "physical";
        roles = [
          ./nixos/roles/physical/desktop/gnome
          ./nixos/roles/physical/desktop/sway
        ];
        hmRoles = [
          ./home-manager/roles/sops-management
          ./home-manager/roles/desktop/sway
        ];
      };

      # ==============================
      # Servers
      # ==============================

      # ==== LXCs ====================
      build-01 = {
        hostType = "servers";
        serverType = "lxc";
        usesHomeManager = true;
        hmRoles = [
          ./home-manager/roles/sops-management
        ];
      };

      auth-01 = {
        hostType = "servers";
        serverType = "lxc";
        roles = [
          ./nixos/roles/server/auth
        ];
      };

      prox-01 = {
        hostType = "servers";
        serverType = "lxc";
        roles = [
          ./nixos/roles/server/proxy
        ];
      };

      avahi-01 = {
        hostType = "servers";
        serverType = "lxc";
        roles = [
          ./nixos/roles/server/mdns-repeater
        ];
      };

      # ==== VMs =====================
      backup-01 = {
        hostType = "servers";
        serverType = "vm";
        roles = [
          ./nixos/modules/backup/server
        ];
      };

      mine-01 = {
        hostType = "servers";
        serverType = "vm";
        roles = [
          ./nixos/roles/server/minecraft
        ];
      };

      # ==============================
    };
  in rec {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkNixosSystem systems;
  };
}
