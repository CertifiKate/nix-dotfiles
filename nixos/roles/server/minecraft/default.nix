{
  inputs,
  pkgs,
  private,
  config,
  ...
}: let
  minecraft_dir = "/services/minecraft";
  secretsPath = builtins.toString inputs.nix-secrets;
  project_tld = "${private.project_tld}";
in {
  imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];
  nixpkgs.overlays = [inputs.nix-minecraft.overlay];

  CertifiKate.backup_service = {
    paths = [
      minecraft_dir
    ];
  };

  # Setup DDNS service using Cloudflare
  sops.secrets."cloudflare_dyndns_token" = {
    sopsFile = "${secretsPath}/secrets/dyndns.yaml";
  };

  services.cloudflare-dyndns = {
    enable = true;
    ipv4 = true;
    ipv6 = false;
    domains = [
      "mc.${project_tld}"
    ];
    apiTokenFile = config.sops.secrets."cloudflare_dyndns_token".path;
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;

    openFirewall = true;

    dataDir = minecraft_dir;

    servers.vanilla = {
      enable = true;
      enableReload = true;
      package = pkgs.paperServers.paper-1_21_6;
      serverProperties = {
        motd = "Kate's NEW NEW Minecraft server";
        hide-online-players = true;
        difficulty = "normal";
        enforce-whitelist = true;
        white-list = true;
        server-port = 25565;
        spawn-protection = 0;
        level-seed = "1217942224227008520";
      };
    };
  };
}
