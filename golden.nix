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

  services.getty.autologinUser = "server_admin";
}
