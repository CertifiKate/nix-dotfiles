{pkgs, ...}: let
in {
  imports = [
    ./ssh-client.nix
  ];

  # Configure our git config
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
    extraConfig = {
      init.defaultBranch = "main";
    };
  };
}
