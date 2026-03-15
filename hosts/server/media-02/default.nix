{...}: {
  imports = [
    ../../../nixos/roles/server/common/media_server
    ../../../nixos/roles/server/media_dl
  ];

  networking.hostName = "media-02";
}
