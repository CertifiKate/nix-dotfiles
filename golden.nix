{
  inputs,
  config,
  pkgs,
  lib,
  ...
}:
#
# Minimal config for golden images. Must be entirely independent
# ie. not require any secrets, flake inputs, etc.
#
{
  imports = [
    ./base.nix
    ./users/server_admin.nix
    ./users/deploy_user.nix
  ];

  nix.settings.trusted-users = [
    "server_admin"
  ];

  environment.systemPackages = with pkgs; [
    ranger
    btop
    python3
  ];

  services.openssh.enable = true;

  # Lets Incus control the golden image (useful for setting IP/Hostname prior to actually setting up)
  services.cloud-init.enable = true;
  services.cloud-init.network.enable = true;
  services.cloud-init.settings = {
    manage_etc_hosts = true;
    preserve_hostname = false;
  };

  networking.useDHCP = lib.mkForce true;
  networking.useNetworkd = lib.mkForce false;
  systemd.network.enable = lib.mkForce false;
  networking.hostName = lib.mkForce "";

  services.resolved.enable = false;
  networking.nameservers = ["1.1.1.1" "8.8.8.8"];

  services.getty.autologinUser = "server_admin";
}
