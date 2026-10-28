#
# RDP thin client - app launcher entry per remote desktop host (ie. mgmt-01)
#
{
  config,
  lib,
  pkgs,
  vars,
  ...
}: let
  cfg = config.CertifiKate.rdpClient;

  mkRdpEntry = host: {
    name = "rdp-${host}";
    value = {
      name = "RDP: ${host}";
      genericName = "Remote Desktop";
      icon = "preferences-desktop-remote-desktop";
      categories = ["Network" "RemoteAccess"];
      exec = "${pkgs.freerdp}/bin/sdl-freerdp /v:${host} /u:${vars.user} /sec:tls -authentication /dynamic-resolution +clipboard /cert:tofu";
    };
  };
in {
  options.CertifiKate.rdpClient = {
    hosts = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [];
      description = "Hosts to create RDP launcher entries for";
    };
  };

  config = {
    home.packages = with pkgs; [
      freerdp
      # For ad-hoc connections to anything not listed above
      remmina
    ];

    xdg.desktopEntries = lib.listToAttrs (map mkRdpEntry cfg.hosts);
  };
}
