# Graphical desktop over RDP (XFCE + xrdp)
# Generic on purpose - other roles decide what the box is actually for
{
  config,
  lib,
  pkgs,
  ...
}: {
  config = lib.mkIf config.CertifiKate.roles.server.remote_desktop.enable {
    services.xserver = {
      enable = true;
      desktopManager.xfce.enable = true;
    };

    services.xrdp = {
      enable = true;
      openFirewall = true;
      defaultWindowManager = "xfce4-session";
    };

    environment.systemPackages = with pkgs; [
      firefox
      xfce4-terminal
    ];
  };
}
