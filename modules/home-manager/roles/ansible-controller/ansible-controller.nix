{
  inputs,
  pkgs,
  vars,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  home.packages = with pkgs; [
    ansible
    # python312Packages.proxmoxer
  ];

  sops.secrets."ansible_ssh_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.ssh/ansible-key";
  };

  programs.zsh.shellAliases = {
    "ansiblepb" = "ansible-playbook --ask-vault-pass -i inventory/shared.yml";
  };
}
