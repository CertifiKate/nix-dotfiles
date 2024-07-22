{ inputs, config, pkgs, ... }:
# Minimal config for golden images

{
  imports = [
    ./users/kate.nix
    ./users/ansible.nix
  ];

  time.timeZone = "Australia/Adelaide";
  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    ranger
    btop
    git
    python3
  ];

  users = {
    mutableUsers = false;
  };

  services.openssh.enable = true;

  # If we change this things will be sad
  system.stateVersion = "23.11";
}