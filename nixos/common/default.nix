{
  inputs,
  pkgs,
  user,
  ...
}:
#
# Role used for every host
# Can use secrets, flake inputs, etc.
#
let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  imports = [
    ../../users/${user}.nix
    ../modules/zsh
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

  environment.systemPackages = with pkgs; [
    ranger
    btop
    dig
    tree
    traceroute
  ];

  # Keep SSH agent in sudo
  security.sudo = {
    extraConfig = ''
      Defaults env_keep+=SSH_AUTH_SOCK
      Defaults timestamp_timeout=30
    '';
  };

  # Auto clean old store files
  nix.gc = {
    automatic = true;
    dates = "weekly";
  };
}
