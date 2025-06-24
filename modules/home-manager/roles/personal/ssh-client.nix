{
  inputs,
  lib,
  vars,
  ...
}: let
  secretsPath = builtins.toString inputs.nix-secrets;
in {
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    forwardAgent = true;
  };

  # Add all of our private keys

  # For low-security stuff, logging into lxc/vms, etc.
  sops.secrets."${vars.user}_ssh_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_${vars.user}";
  };

  # For github exclusively
  sops.secrets."${vars.user}_github_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_github";
  };

  # For higher security stuff, ie. proxmox hosts, github as a fallback
  # /should/ be able to do anything the low-sec ones can do
  sops.secrets."${vars.user}_yubikey_5c_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5c";
  };
  sops.secrets."${vars.user}_yubikey_5_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5";
  };

  # Github ssh config
  programs.ssh.matchBlocks = {
    "github.com" = lib.hm.dag.entryBefore ["*"] {
      user = "git";
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_github"
      ];
    };
    "*.srv" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_${vars.user}"
      ];
    };
    "*.dmz" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5c"
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5"
      ];
    };
    "*.infra" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5c"
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5"
      ];
    };
    "*" = {
      identityFile = [
        "/home/${vars.user}/.ssh/id_ed25519_${vars.user}"
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5c"
        "/home/${vars.user}/.ssh/id_ed25519_sk_rk_yubikey5"
      ];
    };
  };
}
