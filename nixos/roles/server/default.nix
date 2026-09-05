{
  imports = [
    ./common/default.nix
    ./common/options.nix
    ./common/media_server

    ./services/auth
    ./services/backup
    ./services/budget
    ./services/cloudflared
    ./services/jellyfin
    ./services/library
    ./services/mdns-repeater
    ./services/media_dl
    ./services/metrics_relay
    ./services/minecraft
    ./services/monitoring
    ./services/nix-builder
    ./services/proxy
  ];
}
