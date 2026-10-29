#
# Profile for servers - both Incus hypervisors and the instances running on them
#
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."modules/profiles/server" = {lib, ...}: {
    imports = [
      nixos."modules/profiles/common"
      nixos."modules/users/server-admin"
      nixos."modules/users/deploy-user"
      nixos."roles/server/common/media-group"

      # All servers should have the backup client, but the actual paths are defined in the service modules
      nixos."modules/backup/client"
    ];

    nix.settings.trusted-users = [
      "server_admin"
      "deploy_user"
    ];

    # Don't need many generations - only keep them for immediate post-deploy rollback
    nix.gc = lib.mkForce {
      automatic = true;
      dates = "daily";
      options = "--delete-older-than 2d";
    };

    services.openssh = {
      enable = true;

      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
    };
  };
}
