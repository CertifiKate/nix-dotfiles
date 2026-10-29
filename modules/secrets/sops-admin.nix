#
# Lets this machine's user edit and manage sops secrets
#
{config, ...}: let
  inherit (config.meta) secretsPath user;
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.nixos."modules/secrets/sops-admin" = {
    # Placed by the system rather than home-manager, so the administration key stays out of
    # anything the shared home-manager key can decrypt
    sops.secrets."${user}_sops_admin_key" = {
      sopsFile = "${secretsPath}/secrets/sops-admin.yaml";
      owner = user;
      mode = "0400";
      path = "/home/${user}/.config/sops/age/keys.txt";
    };

    home-manager.users.${user}.imports = [homeManager."modules/secrets/sops-admin"];
  };

  flake.modules.homeManager."modules/secrets/sops-admin" = {pkgs, ...}: {
    home.packages = with pkgs; [
      sops
      age
    ];
  };
}
