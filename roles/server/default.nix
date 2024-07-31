# Essentially we just want to de-dupe roles/lxcs and roles/vms
{ pkgs, ...}:
{
  imports = [
    ../../users/ansible.nix
    ../../users/server_admin.nix
    ./vs-code-server.nix
  ];

  # For ansible support
  #TODO Do we even really need this anymore? Just for provisioning? Can it be moved to the golden image config and removed later?
  environment.systemPackages = with pkgs; [
    python3
  ];


  # TODO: Consider removing ansible once we've finished migration
  # TODO: One central build/deploy server? Pushes out to all hosts on regular basis..?
  nix.settings.trusted-users = [
    "ansible"
    "server_admin"
  ];

  services.openssh = {
    enable = true;

    settings.PasswordAuthentication = false;
    settings.KbdInteractiveAuthentication = false;
    settings.PermitRootLogin = "no";
  };
}