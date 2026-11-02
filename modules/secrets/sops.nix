#
# sops-nix for home-manager, decrypted with the key from secrets/home-manager-init.yaml
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.meta) secretsPath user;
in {
  flake.modules.homeManager."modules/secrets/sops" = {
    imports = [inputs.sops-nix.homeManagerModules.sops];

    sops = {
      defaultSopsFile = "${secretsPath}/secrets/home-manager.yaml";

      age = {
        keyFile = "/home/${user}/.config/sops-age.txt";
        generateKey = false;
      };
    };
  };
}
