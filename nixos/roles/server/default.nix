# Essentially we just want to de-dupe roles/lxcs and roles/vms
{pkgs, ...}: {
  imports = [
    ../../../users/server_admin.nix
    ../../../users/deploy_user.nix
    ./vs-code-server.nix
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
