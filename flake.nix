{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-24.05";
    sops-nix.url = "github:Mic92/sops-nix";
  };

  outputs = { self, nixpkgs, sops-nix }:
    let 
      system = "x86_64-linux";
    in {

      nixpkgs.system = "${system}";

      nixosConfigurations."l-auth-01" = nixpkgs.lib.nixosSystem {
        modules = [ 
          ./base.nix 
          ./hosts/auth-01.nix
          sops-nix.nixosModules.sops
        ];
      };
      
      nixosConfigurations."build-01" = nixpkgs.lib.nixosSystem {
        modules = [ 
          ./base.nix 
          ./hosts/build-01
          sops-nix.nixosModules.sops
        ];
      };
    };
}
