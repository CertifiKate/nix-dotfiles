{
  inputs,
  nixpkgs,
  home-manager,
  hostName,
  user,
  systemType ? "physical",
  serverType ? null,
  roles ? [],
  hmRoles ? [],
  extraModules ? [],
  colmenaConfig ? {},
  nodes ? [],
  ...
}:
# Inspired by https://github.com/Baitinq/nixos-config/blob/31f76adafbf897df10fe574b9a675f94e4f56a93/hosts/default.nix
let
  commonNixOSModules = hostName: systemType: [
    # Set common config options
    {
      networking.hostName = hostName;
      nix.settings.experimental-features = ["nix-command" "flakes"];
    }

    # Include our host specific config
    ./hosts/${systemType}/${hostName}

    # Absolute minimum config required
    ./base.nix

    # Include our shared configuration
    ./nixos/common

    # Add in sops
    inputs.sops-nix.nixosModules.sops
  ];

  mkNixRoles = roles: (map (n: ./nixos/roles/${n}) roles);
  mkHMRoles = roles: (map (n: ./home-manager/roles/${n}) roles);

  mkHost = hostName: user: systemType: serverType: roles: hmRoles: extraModules: colmenaConfig:
    if systemType == "server"
    then
      # If it's a NixOS server system. Not intended for end-user use, so no home-manager modules
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules =
          # Shared modules
          commonNixOSModules hostName systemType
          # Add all our specified roles
          ++ mkNixRoles roles
          ++ [
            ./nixos/roles/server
            ./nixos/roles/server/${serverType}
            ./nixos/modules/backup
          ]
          ++ extraModules;

        specialArgs = {
          inherit inputs;
          inherit user;
          # A .json file from the nix-secrets repo with non-important info.
          # Stuff we just don't want public (ie. project_tld) but don't care if it's in the nix store
          private = builtins.fromJSON (builtins.readFile "${builtins.toString inputs.nix-secrets}/private.json");
          colmenaConfig = colmenaConfig;
        };
      }
    else if systemType == "standalone"
    then {
      # TODO Add standalone home-manager
    }
    else
      # If it's a NixOS end-user system (this could be a server VM!)
      nixpkgs.lib.nixosSystem {
        system = "x86_64-linux";

        modules =
          # Shared modules
          commonNixOSModules hostName systemType
          # Add all our specified roles
          ++ mkNixRoles roles
          ++ extraModules
          # Add all Home-Manager configurations + specified HM roles
          ++ [
            home-manager.nixosModules.home-manager
            {
              # Add sops age-key to use for home-manager to decrypt sops secrets (without needing to add it ourselves)
              sops.secrets."home_manager_user_key" = {
                sopsFile = "${builtins.toString inputs.nix-secrets}/secrets/home-manager-init.yaml";
                path = "/home/${user}/.config/sops-age.txt";
                owner = user;
              };

              home-manager.extraSpecialArgs = {
                inherit inputs;
                inherit (inputs) nix-colors;
                inherit user;
              };

              home-manager.backupFileExtension = "backup";
              home-manager.useGlobalPkgs = true;
              home-manager.useUserPackages = true;
              home-manager.users.${user}.imports =
                [
                  ./home.nix
                  ./home-manager/common
                  inputs.sops-nix.homeManagerModules.sops
                ]
                # Add specified home-manager roles
                ++ mkHMRoles hmRoles;
            }
          ];
        specialArgs = {
          inherit inputs;
          inherit user;
          # A .json file from the nix-secrets repo with non-important info.
          # Stuff we just don't want public (ie. project_tld) but don't care if it's in the nix store
          private = builtins.fromJSON (builtins.readFile "${builtins.toString inputs.nix-secrets}/private.json");
        };
      };
in
  mkHost hostName user systemType serverType roles hmRoles extraModules colmenaConfig
