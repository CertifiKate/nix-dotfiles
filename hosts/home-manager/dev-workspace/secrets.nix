#
# dev-workspace, plus our keys for machines that have the home-manager age key and can fetch
# nix-secrets. install.sh picks this one by itself when it can
#
{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) homeManager;
in {
  configurations.home.dev-workspace-secrets.module = {
    config,
    lib,
    ...
  }: {
    imports = [
      homeManager."hosts/home-manager/dev-workspace"
      homeManager."modules/secrets/sops"
      homeManager."modules/personal/ssh-client"
    ];

    # sops-nix only decrypts through a systemd user service, and workspaces don't have systemd. /tmp
    # goes with the container, so nothing decrypted is kept on the home volume
    home.activation.sopsWithoutSystemd = lib.hm.dag.entryAfter ["linkGeneration" "sops-nix"] ''
      export XDG_RUNTIME_DIR=''${XDG_RUNTIME_DIR:-/tmp/runtime-$(id -u)}
      run mkdir -p -m 700 "$XDG_RUNTIME_DIR"
      run ${lib.escapeShellArgs config.systemd.user.services.sops-nix.Service.ExecStart}
    '';
  };
}
