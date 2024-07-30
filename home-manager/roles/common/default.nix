{inputs, outputs, lib, config, pkgs, ...}:
{
  # TODO: Add github key from sops
  programs.home-manager.enable = true;
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
  };
}