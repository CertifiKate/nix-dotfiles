{...}: {
  imports = [
    ../../../nixos/roles/common/media_server
    ../../../nixos/roles/server/media_dl
  ];

  networking.hostName = "media-02";
}
