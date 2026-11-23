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

      # Collect garbage mid-build once free space drops below 1G, until 3G is free. One big
      # build (ie. an ISO) can fill the disk long before the timer comes round
      min-free = 1024 * 1024 * 1024;
      max-free = 3 * 1024 * 1024 * 1024;
    };

    # Everything here is a cache, so there's no need for old generations either
    nix.gc = lib.mkOverride 40 {
      automatic = true;
      dates = "hourly";
      options = "-d";
    };

    CertifiKate.persist.localDirectories = [build_dir];

    # Wipe build directory on boot so we don't fill up disk
    systemd.tmpfiles.rules = ["D! ${build_dir} 0755 root root -"];

    # Disable remote building (bc this should be doing remote building!!)
    CertifiKate.remoteBuilders.enable = lib.mkForce false;
  };
}
