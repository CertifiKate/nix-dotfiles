{ inputs, config, pkgs, ... }:

let 
  secretsPath = builtins.toString inputs.nix-secrets;

  timezone = "Australia/Adelaide";

in {

  imports = [
    ./users/kate.nix
    ./modules/zsh
  ];

  # ==============================
  # Shared Sops configuration
  # ==============================
  sops = {
    defaultSopsFile = "${secretsPath}/secrets/shared.yaml";

    # Don't use SSH keys
    age.sshKeyPaths = [];
    gnupg.sshKeyPaths = [];

    age = {
      keyFile = "/etc/sops-age.txt";
      generateKey = false;
    };
  };
  # ==============================

  # ==============================
  # General System Config
  # ==============================
  time.timeZone = timezone;

  nix.settings.experimental-features = [ "nix-command" "flakes" ];

  environment.systemPackages = with pkgs; [
    ranger
    btop
    git
  ];

  users = {
    mutableUsers = false;
  };

  # Keep SSH agent in sudo
  security.sudo = {
    extraConfig = "Defaults env_keep+=SSH_AUTH_SOCK";
  };

  # Auto clean old store files
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };

  # ==============================

  # TODO: Find a way to add this into users/kate.nix without breaking golden image
  sops.secrets."users_kate_password_hash".neededForUsers = true;
  users.users.kate = {
    isNormalUser = true;
    hashedPasswordFile = config.sops.secrets."users_kate_password_hash".path;
  };

  # TODO: Move this to home manager
  programs.git.config = {
    user.name = "CertifiKate";
    user.email = "131977850+CertifiKate@users.noreply.github.com";
  };

  # TODO: Look into adding a different remote deployment user
  nix.settings.trusted-users = [
    "ansible"
  ];

  # If we change this things will be sad
  system.stateVersion = "23.11";
}