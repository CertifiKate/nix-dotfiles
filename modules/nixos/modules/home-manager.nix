{
  inputs,
  vars,
  ...
}: {
  # Minimal setup for home-manager

  # Add sops age-key to use for home-manager to decrypt sops secrets (without needing to add it ourselves)
  sops.secrets."home_manager_user_key" = {
    sopsFile = "${builtins.toString inputs.nix-secrets}/secrets/home-manager-init.yaml";
    path = "/home/${vars.user}/.config/sops-age.txt";
    owner = vars.user;
  };

  home-manager = {
    backupFileExtension = "backup";
    extraSpecialArgs = {
      inherit inputs vars;
    };
    useGlobalPkgs = true;
    useUserPackages = true;
    # Common imports for home-manager
    users.${vars.user}.imports = [
      ../../home-manager/common
      inputs.sops-nix.homeManagerModules.sops
    ];
  };
}
