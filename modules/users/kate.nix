{config, ...}: let
  inherit (config.meta) sshKeys;
in {
  flake.modules.nixos."modules/users/kate" = {config, ...}: {
    sops.secrets."users_kate_password_hash".neededForUsers = true;

    users.users.kate = {
      description = "Kate";
      isNormalUser = true;
      extraGroups = ["wheel" "dialout"];
      openssh.authorizedKeys.keys = sshKeys;
      hashedPasswordFile = config.sops.secrets."users_kate_password_hash".path;
    };
  };
}
