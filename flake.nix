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
        specialArgs = {inherit inputs outputs vars;};
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
          ./nixos/common
          ./hosts/server
          ./nixos/modules/backup
          ./nixos/roles/server/${serverType}
        ];
      };
  in {
    formatter = nixpkgs.lib.genAttrs systems (system: nixpkgs.legacyPackages.${system}.alejandra);
    # Collection of all of our configs
    nixosConfigurations = {
      # Laptop
      aurora = mkPhysicalNixOSConfig ./hosts/physical/aurora;

      # Servers
      # TODO: all of this...
      # prox-01 = mkServerNixOSConfig ./hosts/server/prox-01 "lxc";
    };
  };
}
