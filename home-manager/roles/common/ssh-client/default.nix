{
  inputs,
  lib,
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
  sops.secrets."kate_ssh_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519_kate";
  };

  # For github exclusively
  sops.secrets."kate_github_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519_github";
  };

  # For higher security stuff, ie. proxmox hosts, github as a fallback
  # /should/ be able to do anything the low-sec ones can do
  sops.secrets."kate_yubikey_5c_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519_sk_rk_yubikey5c";
  };
  sops.secrets."kate_yubikey_5_key" = {
    sopsFile = "${secretsPath}/secrets/home-manager.yaml";
    path = "/home/kate/.ssh/id_ed25519_sk_rk_yubikey5";
  };

  # Github ssh config
  programs.ssh.matchBlocks = {
    "github.com" = lib.hm.dag.entryBefore ["*"] {
      user = "git";
      identityFile = [
        "/home/kate/.ssh/id_ed25519_github"
      ];
    };
    "*.srv" = lib.hm.dag.entryBefore ["*"] {
      identityFile = [
        "/home/kate/.ssh/id_ed25519_kate"
      ];
    };
    "*" = {
      identityFile = [
        "/home/kate/.ssh/id_ed25519_kate"
        "/home/kate/.ssh/id_ed25519_sk_rk_yubikey5c"
        "/home/kate/.ssh/id_ed25519_sk_rk_yubikey5"
      ];
    };
  };
}
