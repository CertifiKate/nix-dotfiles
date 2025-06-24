{
  inputs,
  pkgs,
  vars,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  # The administration key (not the home-manager key)
  sops.secrets."${vars.user}_sops_admin_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.config/sops/age/keys.txt";
  };

  home.packages = with pkgs; [
    sops
    age
  ];
}
