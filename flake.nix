{
  inputs = {
    # I want to use unstable by default but for some things use stable
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.05";

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
    ...
  } @ inputs: let
    inherit (self) outputs;

    # Set the primary/default user. Can be overwritten on a system level
    vars.user = "kate";

    # Restructuring based on https://github.com/eh8/chenglab/blob/main/flake.nix

    systems = ["x86_64-linux"];

    # Generic NixOS config for all systems
    mkNixOSConfig = {
      path,
      extraModules ? [],
    }:
      nixpkgs.lib.nixosSystem {
        specialArgs = {
          inherit inputs outputs vars;
          # A .json file from the nix-secrets repo with non-important info.
          # Stuff we just don't want public (ie. project_tld) but don't care if it's in the nix store
          private = builtins.fromJSON (builtins.readFile "${builtins.toString inputs.nix-secrets}/private.json");
        };
        modules =
          [
            ./base.nix
            ./nixos/common
            # Add in sops
            inputs.sops-nix.nixosModules.sops
            path
          ]
          ++ extraModules;
      };

    # Defines additional modules for physical machines
    mkPhysicalNixOSConfig = path:
      mkNixOSConfig {
        path = path;
        extraModules = [
          ./hosts/physical
        ];
      };

    # Defines additional modules for servers
    mkServerNixOSConfig = path: serverType:
      mkNixOSConfig {
        path = path;
        extraModules = [
          ./hosts/server
          ./nixos/roles/server/${serverType}
          ./nixos/common
          ./nixos/modules/backup
        ];
      };
  in {
    formatter = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.alejandra);

    # Collection of all of our configs
    nixosConfigurations = {
      # === Laptop ===
      aurora = mkPhysicalNixOSConfig ./hosts/physical/aurora;
      # === Desktop ===
      cosmos = mkPhysicalNixOSConfig ./hosts/physical/cosmos;

      # === Servers ===
      # LXCs
      auth-01 = mkServerNixOSConfig ./hosts/server/auth-01 "lxc";
      avahi-01 = mkServerNixOSConfig ./hosts/server/avahi-01 "lxc";
      build-01 = mkServerNixOSConfig ./hosts/server/build-01 "lxc";
      media-01 = mkServerNixOSConfig ./hosts/server/media-01 "lxc";
      media-02 = mkServerNixOSConfig ./hosts/server/media-02 "lxc";
      prox-01 = mkServerNixOSConfig ./hosts/server/prox-01 "lxc";
      util-01 = mkServerNixOSConfig ./hosts/server/util-01 "lxc";
      # VMs
      backup-01 = mkServerNixOSConfig ./hosts/server/backup-01 "vm";
      mine-01 = mkServerNixOSConfig ./hosts/server/mine-01 "vm";
    };
  };
}
