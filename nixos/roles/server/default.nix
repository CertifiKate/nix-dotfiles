{
  imports = [
    ./common/options.nix
    ./common/media_server

    ./services/auth
    ./services/backup
    ./services/budget
    ./services/cloudflared
    ./services/jellyfin
    ./services/mdns-repeater
    ./services/media_dl
    ./services/minecraft
    ./services/nix-builder
    ./services/proxy
  ];
}
