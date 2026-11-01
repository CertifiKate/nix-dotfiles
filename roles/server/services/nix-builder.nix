{
  flake.modules.nixos."roles/server/services/nix-builder" = {
    lib,
    pkgs,
    ...
  }: let
    build_dir = "/build_outputs";
  in {
    users.users."nix-builder" = {
      isNormalUser = true;
      createHome = true;
      shell = pkgs.bash;
      openssh.authorizedKeys.keys = [
        ''command="${pkgs.nix}/bin/nix-daemon --stdio",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONUHmhgpX3dQQpAK+IyWLQQ338uiIY5TgqE3tjOf/2O nix remote builder''
      ];
      group = "nix-builder";
    };

    users.groups."nix-builder" = {};

    nix.settings = {
      trusted-users = ["nix-builder"];
      allowed-users = ["nix-builder"];
      build-dir = build_dir;
    };

    CertifiKate.persist.localDirectories = [build_dir];

    # Wipe build directory on boot so we don't fill up disk
    systemd.tmpfiles.rules = ["D! ${build_dir} 0755 root root -"];

    # Disable remote building (bc this should be doing remote building!!)
    CertifiKate.remoteBuilders.enable = lib.mkForce false;
  };
}
