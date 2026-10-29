#
# home-manager as a NixOS module, with the common home-manager config for our user
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) secretsPath user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.nixos."modules/home-manager" = {
    imports = [inputs.home-manager.nixosModules.home-manager];

    # Add sops age-key to use for home-manager to decrypt sops secrets (without needing to add it ourselves)
    sops.secrets."home_manager_user_key" = {
      sopsFile = "${secretsPath}/secrets/home-manager-init.yaml";
      path = "/home/${user}/.config/sops-age.txt";
      owner = user;
    };

    home-manager = {
      backupFileExtension = "backup";
      useGlobalPkgs = true;
      useUserPackages = true;
      # Common imports for home-manager
      users.${user}.imports = [
        homeManager."modules/home-manager/common"
        inputs.sops-nix.homeManagerModules.sops
      ];
    };
  };
}
