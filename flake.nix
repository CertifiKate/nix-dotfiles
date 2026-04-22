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
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-vscode-extensions = {
      url = "github:nix-community/nix-vscode-extensions";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nix-minecraft.url = "github:Infinidoge/nix-minecraft";
    vpn-confinement.url = "github:Maroka-chan/VPN-Confinement";
    nixos-hardware.url = "github:NixOS/nixos-hardware/master";
    colmena = {
      url = "github:zhaofengli/colmena";
    };
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
    specialArgs = {
      inherit inputs outputs vars;
      private = builtins.fromJSON (builtins.readFile "${toString inputs.nix-secrets}/private.json");
    };

    mkNixOSConfig = {
      path,
      extraModules ? [],
    }: let
      modules =
        [
          ./base.nix
          ./nixos/common
          inputs.sops-nix.nixosModules.sops
          path
        ]
        ++ extraModules;
    in
      (nixpkgs.lib.nixosSystem {
        inherit specialArgs modules;
      })
      // {inherit modules;};

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
          ./nixos/roles/server/common/${serverType}
          ./nixos/common
        ];
      };
    mkIncusHypervisorConfig = path: bootstrap:
      mkNixOSConfig {
        path = path;
        extraModules = [
          ./hosts/server
          (
            if bootstrap
            then ./nixos/roles/server/common/incus-host/bootstrap.nix
            else ./nixos/roles/server/common/incus-host/member.nix
          )
          ./nixos/common
        ];
      };
    # Wrap our system definitions so we can add Colmena outputs to it
    mkColmenaAttr = nixOSConfig: deploymentAttrs: {
      imports = nixOSConfig.modules;
      deployment =
        {
          targetUser = "deploy_user";
        }
        // deploymentAttrs;
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
      # Incus Hypervisors
      # For now, these are VMs on proxmox, will be moved to bare-metal NixOS machines later
      incus-01 = mkIncusHypervisorConfig ./hosts/server/incus/incus-01 true; # This one is our bootstrap node
      incus-02 = mkIncusHypervisorConfig ./hosts/server/incus/incus-02 false;
      incus-03 = mkIncusHypervisorConfig ./hosts/server/incus/incus-03 false;

      # LXCs
      auth-01 = mkServerNixOSConfig ./hosts/server/auth-01 "lxc";
      # avahi-01 = mkServerNixOSConfig ./hosts/server/avahi-01 "lxc";
      build-01 = mkServerNixOSConfig ./hosts/server/build-01 "lxc";
      build-02 = mkServerNixOSConfig ./hosts/server/build-02 "lxc";
      monitor-01 = mkServerNixOSConfig ./hosts/server/monitor-01 "lxc";
      media-01 = mkServerNixOSConfig ./hosts/server/media-01 "lxc";
      media-02 = mkServerNixOSConfig ./hosts/server/media-02 "lxc";
      prox-01 = mkServerNixOSConfig ./hosts/server/prox-01 "lxc";
      util-01 = mkServerNixOSConfig ./hosts/server/util-01 "lxc";
      # VMs
      backup-01 = mkServerNixOSConfig ./hosts/server/backup-01 "vm";
      mine-01 = mkServerNixOSConfig ./hosts/server/mine-01 "vm";

      # === Images ===
      # Golden images to be pushed to Incus
      # Contain nothing interesting except SSH and pre-setup users
      golden-incus-vm = mkNixOSConfig {
        path = ./golden.nix;
        extraModules = [
          ./hosts/server
          "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
          {
            nixpkgs.hostPlatform = {system = "x86_64-linux";};
            system.nixos.distroName = "NixOS Golden LXC";
            system.nixos.label = "golden-lxc";
          }
        ];
      };
      golden-lxc = mkNixOSConfig {
        path = ./golden.nix;
        extraModules = [
          ./hosts/server
          "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
          {
            nixpkgs.hostPlatform = {system = "x86_64-linux";};
            system.nixos.distroName = "NixOS Golden VM";
            system.nixos.label = "golden-vm";
          }
        ];
      };
    };

    colmenaHive = inputs.colmena.lib.makeHive (let
      configs = self.nixosConfigurations;
    in {
      meta = {
        inherit specialArgs;
        nixpkgs = import nixpkgs {
          system = "x86_64-linux";
        };
      };
      # === Hypervisors ===
      "incus-01.infra" = mkColmenaAttr configs.incus-01 {
        tags = ["incus"];
      };
      # "incus-02.infra" = mkColmenaAttr configs.incus-02 {
      #   tags = ["incus"];
      # };
      # "incus-03.infra" = mkColmenaAttr configs.incus-03 {
      #   tags = ["incus"];
      # };

      # === Servers ===
      "auth-01.srv" = mkColmenaAttr configs.auth-01 {
        tags = ["auth"];
      };
      "build-01.srv" = mkColmenaAttr configs.build-01 {
        tags = ["build"];
      };
      "build-02.srv" = mkColmenaAttr configs.build-02 {
        tags = ["build"];
      };
      # "monitor-01.srv" = mkColmenaAttr configs.monitor-01 {
      #   tags = ["monitor"];
      # };
      "media-01.srv" = mkColmenaAttr configs.media-01 {
        tags = ["media"];
      };
      "media-02.srv" = mkColmenaAttr configs.media-02 {
        tags = ["media"];
      };
      "prox-01.srv" = mkColmenaAttr configs.prox-01 {
        tags = ["proxy"];
      };
      "util-01.srv" = mkColmenaAttr configs.util-01 {
        tags = ["util"];
      };
      "backup-01.srv" = mkColmenaAttr configs.backup-01 {
        tags = ["backup"];
      };
      "mine-01.srv" = mkColmenaAttr configs.mine-01 {
        tags = ["minecraft"];
      };
    });
  };
}
