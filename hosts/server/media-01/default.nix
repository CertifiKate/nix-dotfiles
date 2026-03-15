{...}: {
  imports = [
    ../../../nixos/roles/server/common/media_server
    ../../../nixos/roles/server/jellyfin
  ];

  networking.hostName = "media-01";
}
