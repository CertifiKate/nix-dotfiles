# Essentially we just want to de-dupe roles/lxcs and roles/vms
{...}: {
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

  services.openssh = {
    enable = true;

    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };
}
