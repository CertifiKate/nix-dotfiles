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

    user = "kate";

    systems = {
      # ==============================
      # Physical Devices
      # ==============================
      # Lenovo Thinkpad E14 Gen 6 (AMD)
      aurora = {
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
        extraImports = [
          inputs.nixos-hardware.nixosModules.lenovo-thinkpad-e14-amd
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

      # ==============================
      # Server
      # ==============================
      # ==== LXCs ====================
      build-01 = {
        systemType = "server";
        serverType = "lxc";
        # hmRoles = [
        #   ./home-manager/roles/sops-management
        # ];
      };

      auth-01 = {
        systemType = "server";
        serverType = "lxc";
        roles = [
          /server/auth
        ];
      };

      prox-01 = {
        systemType = "server";
        serverType = "lxc";
        roles = [
          /server/proxy
        ];
      };

      avahi-01 = {
        systemType = "server";
        serverType = "lxc";
        roles = [
          /server/mdns-repeater
        ];
      };

      media-01 = {
        systemType = "server";
        serverType = "lxc";
        roles = [
          /server/common/media_server
          /server/jellyfin
        ];
      };

      media-02 = {
        systemType = "server";
        serverType = "lxc";
        roles = [
          /server/common/media_server
          /server/media_dl
        ];
      };

      # ==== VMs =====================
      backup-01 = {
        systemType = "server";
        serverType = "vm";
        extraImports = [
          ./nixos/modules/backup/server
        ];
      };

      mine-01 = {
        systemType = "server";
        serverType = "vm";
        roles = [
          /server/minecraft
        ];
      };
      # ==============================
    };

    mkSystem = host: system:
      import ./hosts.nix (commonInherits
        // {
          hostName = "${host}";
          user = user;
          serverType = system.serverType;
        }
        // system);
  in {
    nixosConfigurations = nixpkgs.lib.mapAttrs mkSystem systems;
  };
}
