{
  inputs,
  pkgs,
  ...
}: let
  minecraft_dir = "/services/minecraft";
in {
  imports = [inputs.nix-minecraft.nixosModules.minecraft-servers];
  nixpkgs.overlays = [inputs.nix-minecraft.overlay];

  CertifiKate.backup_service = {
    paths = [
      minecraft_dir
    ];
  };

  services.minecraft-servers = {
    enable = true;
    eula = true;

    openFirewall = true;

    dataDir = minecraft_dir;

    servers.vanilla = {
      enable = true;
      enableReload = true;
      package = pkgs.paperServers.paper-1_21;
      serverProperties = {
        motd = "Kate's NEW Minecraft server";
        hide-online-players = true;
        difficulty = "normal";
        enforce-whitelist = true;
        server-port = 25565;
        spawn-protection = 0;
      };
    };
  };
}
