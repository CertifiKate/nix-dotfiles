{
  users.users."nix-builder" = {
    isNormalUser = true;
    createHome = false;
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIONUHmhgpX3dQQpAK+IyWLQQ338uiIY5TgqE3tjOf/2O nix remote builder"
    ];
    group = "nix-builder";
  };

  users.groups."nix-builder" = {
  };

  nix.settings.trusted-users = ["nix-builder"];
}
