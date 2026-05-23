{lib, ...}: {
  imports = [
    ../../users/server_admin.nix
    ../../users/deploy_user.nix

    # Import all server roles so configs are shared. Flags enable specific services on each host.
    ../../nixos/roles/server

    # All servers should have backup enabled, but the actual paths are defined in the service modules. This is required to ensure the backup client is installed and configured on all servers.
    ../../nixos/modules/backup/client
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
}
