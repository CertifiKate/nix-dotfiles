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

  outputs = { self, nixpkgs, sops-nix, ... }@inputs:
    let 
      system = "x86_64-linux";
      project_tld = "test.example";
    in {

      nixpkgs.system = "${system}";

      # TODO: I think there is a simpler way to do this
      #       is there a way to set defaults? A generator function?
      nixosConfigurations."auth-01" = nixpkgs.lib.nixosSystem {
        modules = [ 
          ./base.nix
          ./hosts/lxcs
          ./hosts/lxcs/auth-01
          sops-nix.nixosModules.sops
        ];
      };
      
      nixosConfigurations."build-01" = nixpkgs.lib.nixosSystem {
        specialArgs.inputs = inputs;
        modules = [ 
          ./base.nix 
          ./hosts/lxcs
          ./hosts/lxcs/build-01
          sops-nix.nixosModules.sops
        ];
      };

      nixosConfigurations."mine-01" = nixpkgs.lib.nixosSystem {
        modules = [ 
          ./base.nix 
          ./hosts/lxcs
          ./hosts/lxcs/mine-01
          sops-nix.nixosModules.sops
        ];
      };

    };
}
