{pkgs, ...}: let
in {
  imports = [
    ./ssh-client.nix
  ];

  # Configure our git config
  programs.git = {
    enable = true;
    settings = {
      user = {
        name = "CertifiKate";
        email = "131977850+CertifiKate@users.noreply.github.com";
      };
      init.defaultBranch = "main";
    };
  };
}
