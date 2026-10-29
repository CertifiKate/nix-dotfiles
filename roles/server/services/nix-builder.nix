{
  flake.modules.nixos."roles/server/services/nix-builder" = {
    lib,
    pkgs,
    ...
  }: {
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
    };

    # Disable remote building (bc this should be doing remote building!!)
    CertifiKate.remoteBuilders.enable = lib.mkForce false;
  };
}
