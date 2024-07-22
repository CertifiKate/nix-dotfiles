{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";

    nix-secrets = {
      url = "git+ssh://git@github.com/CertifiKate/nix-secrets.git";
      flake = false;
    };

    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
  };

  # Based on https://www.reddit.com/r/NixOS/comments/yk4n8d/comment/iurkkxv
  outputs = { self, nixpkgs, sops-nix, ... } @inputs:
    let

      # Basic configuration modules
      commonModules = name: cfg: [
        # Set common config options
        {
          nix.settings.experimental-features = [ "nix-command" "flakes" ];
          networking.hostName = name;

          # nixpkgs.hostPlatform = "${cfg.system or "x86_64-linux"}";
        }
        
        # Include our host config
        ./hosts/${(cfg.hostType or "servers" )}/${name}

        # Optionally import the generic server role
        (if (cfg.hostType == "servers") then ./roles/server else "" )

        # Optionally import the specific server role - substitutes the hardware config
        (if (cfg.hostType == "servers") then ./roles/server/${cfg.serverType or "lxc"} else "" )

        # Include our shared configuration
        ./base.nix

        sops-nix.nixosModules.sops
      ];

      # Generates the relevant system configuration based on inputs
      mkSystem = name: cfg: nixpkgs.lib.nixosSystem {
        system = cfg.system or "x86_64-linux";

        # Include our common modules, plus any host specified roles
        modules = (commonModules name cfg) ++ (cfg.roles or []);

        specialArgs = {
          inherit inputs; 

          # A .json file from the nix-secrets repo with non-important info. 
          # Stuff we just don't want public (ie. project_tld) but don't care if it's in the nix store
          private = builtins.fromJSON (builtins.readFile ("${builtins.toString inputs.nix-secrets}/private.json"));
        };
      };

      # System definitions
      systems = {

        # ==============================
        # Servers
        # ==============================

        # ==== LXCs ====================
        build-01 = {
          hostType = "servers";
          serverType = "lxc";
        };

        auth-01 = {
          hostType = "servers";
          serverType = "lxc";
          roles = [
            ./roles/auth
          ];
        };

        prox-01 = {
          hostType = "servers";
          serverType = "lxc";
          roles = [
            ./roles/proxy
          ];
        };


        # ==== VMs =====================
        mine-01 = {
          hostType = "servers";
          serverType = "vm";
          roles = [
            ./roles/minecraft
          ];
        };

        # ==============================
      };
    in rec {
      nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;
    };
}
