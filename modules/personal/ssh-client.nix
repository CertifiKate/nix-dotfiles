{config, ...}: let
  inherit (config.meta) secretsPath user;
in {
  flake.modules.homeManager."modules/personal/ssh-client" = {lib, ...}: {
    # Add all of our private keys

    # For low-security stuff, logging into lxc/vms, etc.
    sops.secrets."${user}_ssh_key" = {
      sopsFile = "${secretsPath}/secrets/home-manager.yaml";
      path = "/home/${user}/.ssh/id_ed25519_${user}";
    };

    # For github exclusively
    sops.secrets."${user}_github_key" = {
      sopsFile = "${secretsPath}/secrets/home-manager.yaml";
      path = "/home/${user}/.ssh/id_ed25519_github";
    };

    # For higher security stuff, ie. proxmox hosts, github as a fallback
    # /should/ be able to do anything the low-sec ones can do
    sops.secrets."${user}_yubikey_5c_key" = {
      sopsFile = "${secretsPath}/secrets/home-manager.yaml";
      path = "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5c";
    };
    sops.secrets."${user}_yubikey_5_key" = {
      sopsFile = "${secretsPath}/secrets/home-manager.yaml";
      path = "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5";
    };

    programs.ssh = {
      enable = true;
      enableDefaultConfig = false;
      settings = {
        "github.com" = lib.hm.dag.entryBefore ["*"] {
          User = "git";
          IdentityFile = [
            "/home/${user}/.ssh/id_ed25519_github"
          ];
        };
        "*.srv" = lib.hm.dag.entryBefore ["*"] {
          IdentityFile = [
            "/home/${user}/.ssh/id_ed25519_${user}"
          ];
        };
        "*.dmz" = lib.hm.dag.entryBefore ["*"] {
          IdentityFile = [
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5c"
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5"
          ];
        };
        "*.infra" = lib.hm.dag.entryBefore ["*"] {
          IdentityFile = [
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5c"
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5"
          ];
        };
        "*" = {
          AddKeysToAgent = "yes";
          ForwardAgent = true;
          IdentityFile = [
            "/home/${user}/.ssh/id_ed25519_${user}"
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5c"
            "/home/${user}/.ssh/id_ed25519_sk_rk_yubikey5"
          ];
        };
      };
    };
  };
}
