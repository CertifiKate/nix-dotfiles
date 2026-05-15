{
  pkgs,
  vars,
  lib,
  config,
  ...
}: let
in {
  options = {
    CertifiKate.roles.physical.desktop.gaming.autoStartSteam = lib.mkEnableOption "Automatically log in to a gamescope session with steam big picture mode running";
  };

  config = {
    environment.systemPackages = with pkgs; [
      gamescope-wsi
      (pkgs.writeShellScriptBin "steamos-session-select" ''
        case "$1" in
          "gnome"|"desktop")
            # kill gamescope session, GDM takes over
            systemctl --user stop steam-session.target
            loginctl terminate-session "$XDG_SESSION_ID"
            ;;
          "steamos"|"gamescope"|"")
            systemctl --user restart steam-session.target
            ;;
          *)
            systemctl --user stop steam-session.target
            loginctl terminate-session "$XDG_SESSION_ID"
            ;;
        esac
      '')
    ];

    hardware.steam-hardware.enable = true;
    hardware.graphics = {
      enable = true;
      enable32Bit = true;
    };

    programs = {
      gamescope = {
        enable = true;
        capSysNice = false;
      };
      steam = {
        enable = true;
        gamescopeSession = {
          enable = true;
          args = ["--adaptive-sync" "--rt"];
          steamArgs = ["-tenfoot" "-pipewire-dmabuf"];
        };
      };
    };
    # Set it up to auto-login to steam big picture within gamescope
    services.displayManager = lib.mkIf config.CertifiKate.roles.physical.desktop.gaming.autoStartSteam {
      gdm.enable = true;
      autoLogin = {
        enable = true;
        user = vars.user;
      };
      defaultSession = "steam";
    };

    # Automatically put the machine to sleep after 15min idle in steam big picture, and wake back up when input is detected (or WOL)
    systemd.user.services.steam-idle-sleep = lib.mkIf config.CertifiKate.roles.physical.desktop.gaming.autoStartSteam {
      description = "Sleep after 15min idle in Steam session";
      # only run when the steam session is active
      partOf = ["steam-session.target"];
      wantedBy = ["steam-session.target"];
      serviceConfig = {
        ExecStart = ''
          ${pkgs.swayidle}/bin/swayidle -w \
            timeout 900 'systemctl suspend' \
            resume 'systemctl --user restart steam-session.target'
        '';
        Restart = "on-failure";
      };
    };
  };
}
