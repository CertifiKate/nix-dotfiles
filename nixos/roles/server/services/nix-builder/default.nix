{
  lib,
  config,
  pkgs,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.CertifiKate.roles.server.nix_builder.enable {
      users.users."nix-builder" = {
        isNormalUser = true;
        createHome = false;
        shell = "${pkgs.util-linux}/bin/nologin";
        openssh.authorizedKeys.keys = [
          ''command="${pkgs.nix}/bin/nix-store --serve --write",restrict ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONUHmhgpX3dQQpAK+IyWLQQ338uiIY5TgqE3tjOf/2O nix remote builder''
        ];
        group = "nix-builder";
      };

      users.groups."nix-builder" = {};

      nix.settings = {
        # trusted-users intentionally omitted
        allowed-users = ["nix-builder"];
      };
    })
  ];
}
