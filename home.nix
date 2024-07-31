{ inputs, ...}:

# Absolute minimum config for home manager

# TODO: Get username programatically?
let
  secretsPath = builtins.toString inputs.nix-secrets;
  user = "kate";
in
{
  home = {
    username = "${user}";
    homeDirectory = "/home/${user}";
  };

  sops = {
    defaultSopsFile = "${secretsPath}/secrets/home-manager.yaml";
    
    age = {
      keyFile = "/home/${user}/.config/sops-age.txt";
      generateKey = false;
    };
  };


  home.stateVersion = "24.05";
}