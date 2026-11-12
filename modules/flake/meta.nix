#
# Values shared by every module. Read them from the flake-parts `config` (ie. `config.meta.user`)
# instead of passing them through specialArgs
#
{
  inputs,
  lib,
  ...
}: {
  options.meta = {
    user = lib.mkOption {
      type = lib.types.str;
      default = "kate";
      description = "The primary/default user";
    };
    sshKeys = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGo9WY7TLTIFt52azw9w8+JXUATPjIAO17ktKDuWguMqAAAADHNzaDprYXRlQHNzaA== kate@yubikey5c"
        "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP4/ABrztYqDH1yZR0vIxUITa/M+CdaodvztkGZFkWaYAAAADHNzaDpLYXRlIFNTSA== kate@yubikey5"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAICAbwJzWf4kJ3WTRuRGqXSQo8gPd66EvvRFXa82ZOiTw kate@nix"
      ];
      description = "SSH public keys allowed to log in as the primary user (and root on installers)";
    };
    secretsPath = lib.mkOption {
      type = lib.types.str;
      readOnly = true;
      default = toString inputs.nix-secrets;
      description = "Path to the nix-secrets repo";
    };
    private = lib.mkOption {
      type = lib.types.lazyAttrsOf lib.types.raw;
      readOnly = true;
      default = builtins.fromJSON (builtins.readFile "${toString inputs.nix-secrets}/private.json");
      description = "Non-secret but private values (domains, etc.)";
    };
    remoteBuilders = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [
        "build-01.srv"
        "build-02.srv"
      ];
      description = "Hostnames used as remote nix builders";
    };
  };
}
