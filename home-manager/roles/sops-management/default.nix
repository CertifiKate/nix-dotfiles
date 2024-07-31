{ inputs, pkgs, ...}:
let
  secretsPath = builtins.toString inputs.nix-secrets;
in
{

  # The administration key (not the home-manager key)
  sops.secrets."kate_sops_admin_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.config/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    sops
    age
  ];
}