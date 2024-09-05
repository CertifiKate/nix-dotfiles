{inputs, ...}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  imports = [
    ./ssh-client
  ];

  # Configure our git config
  programs.git = {
    enable = true;
    userName = "CertifiKate";
    userEmail = "131977850+CertifiKate@users.noreply.github.com";
  };

  # Enable ZSH configuration for more specific configs (i.e adding aliases for roles)
  # (this /seems/ to be able to run alongside the NixOS config without issue)
  programs.zsh.enable = true;
}
