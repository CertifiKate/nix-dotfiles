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
    ./services/metrics_relay
    ./services/monitoring
    ./services/mdns-repeater
    ./services/media_dl
    ./services/minecraft
    ./services/nix-builder
    ./services/proxy
  ];
}
