# Graphical desktop over RDP (XFCE + xrdp)
# Generic on purpose - other roles decide what the box is actually for
{
  flake.modules.nixos."roles/server/services/remote-desktop" = {pkgs, ...}: {
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
