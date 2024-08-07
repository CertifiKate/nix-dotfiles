{
  inputs,
  config,
  pkgs,
  ...
}:
#
# The absolute minimum system config required for my nix setup
# Shouldn't be required to use flakes to run this, nor any secrets
# Should be compatible with ALL hosts, including golden images
#
let
  timezone = "Australia/Adelaide";
in {
  # ==============================
  # General System Config
  # ==============================
  time.timeZone = timezone;

  nix.settings.experimental-features = ["nix-command" "flakes"];

  environment.systemPackages = with pkgs; [
    git
  ];

  users = {
    mutableUsers = false;
  };

  # Auto clean old store files
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # ==============================

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  # If we change this things will be sad
  system.stateVersion = "24.05";
}
