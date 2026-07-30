{
  pkgs,
  vars,
  lib,
  config,
  ...
}: let
  cfg = config.CertifiKate.roles.physical.desktop.gaming;
  cec-ctl = "${pkgs.v4l-utils}/bin/cec-ctl";

  # Monitors CEC traffic and suspends the PC when the TV broadcasts a standby.
  # Uses --monitor (receive-only) so one-shot wake/standby commands can open the
  # device concurrently without conflicting.
  cecDaemonScript = pkgs.writeShellScript "cec-daemon" ''
    ${cec-ctl} -s --osd-name "PC" --playback --monitor | while IFS= read -r line; do
      if echo "$line" | grep -q "STANDBY"; then
        systemctl suspend
      fi
    done
  '';

  cecWakeScript = pkgs.writeShellScript "cec-wake-tv" ''
    sleep 3
    ${cec-ctl} -s --osd-name "PC" --playback --to 0 --image-view-on
    sleep 1
    phys_addr=$(${cec-ctl} -s --playback -x 2>/dev/null | grep -o '[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+' | head -1)
    if [ -n "$phys_addr" ]; then
      ${cec-ctl} -s --osd-name "PC" --playback --active-source phys-addr="$phys_addr"
    fi
  '';

  cecStandbyScript = pkgs.writeShellScript "cec-standby-tv" ''
    ${cec-ctl} -s --osd-name "PC" --playback --to 0 --standby
  '';
in {
  options = {
    CertifiKate.roles.physical.desktop.gaming.autoStartSteam = lib.mkEnableOption "Automatically log in to a gamescope session with steam big picture mode running";
  };

  config = {
    environment.systemPackages = with pkgs; [
      v4l-utils
      gamescope-wsi
      (pkgs.writeShellScriptBin "steamos-session-select" ''
        case "$1" in
          "gnome"|"desktop")
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
        extraPackages = with pkgs; [hidapi];
        gamescopeSession = {
          enable = true;
          args = ["--adaptive-sync" "--rt" "-W" "3840" "-H" "2160"];
          steamArgs = ["-tenfoot" "-pipewire-dmabuf"];
        };
      };
    };

    # CEC access via DP->HDMI adapter
    users.users.${vars.user}.extraGroups = ["video"];

    # Enable wake-from-USB for the Steam Controller dongle (28de:1304).
    # The udev rule sets the flag at boot; the service re-applies it after every resume
    # because the dongle stays enumerated across suspend and never gets an add event on wake.
    services.udev.extraRules = ''
      ACTION=="add", SUBSYSTEM=="usb", ATTRS{idVendor}=="28de", ATTRS{idProduct}=="1304", ATTR{power/wakeup}="enabled"
    '';
    systemd.services.steam-controller-wakeup = {
      description = "Re-enable Steam Controller dongle wake-from-suspend after resume";
      wantedBy = ["post-sleep.target"];
      after = ["post-sleep.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "steam-controller-wakeup" ''
          for dir in /sys/bus/usb/devices/*/; do
            if [ "$(cat "$dir/idVendor" 2>/dev/null)" = "28de" ] && [ "$(cat "$dir/idProduct" 2>/dev/null)" = "1304" ]; then
              echo enabled > "$dir/power/wakeup"
            fi
          done
        '';
      };
    };

    # Monitors CEC traffic and suspends when the TV sends standby
    # conflicts=sleep.target stops it cleanly before suspend; Restart brings it back on resume.
    systemd.services.cec-daemon = {
      description = "CEC monitor — suspends PC when TV remote sends standby";
      wantedBy = ["multi-user.target"];
      after = ["multi-user.target"];
      conflicts = ["sleep.target"];
      before = ["sleep.target"];
      serviceConfig = {
        Type = "simple";
        Restart = "on-failure";
        RestartSec = "5s";
        ExecStart = cecDaemonScript;
      };
    };

    # Sends CEC standby to the TV before the PC suspends
    systemd.services.cec-standby-tv = {
      description = "Send CEC standby to TV before suspending";
      wantedBy = ["sleep.target"];
      before = ["sleep.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cecStandbyScript;
      };
    };

    services.displayManager = lib.mkIf cfg.autoStartSteam {
      gdm.enable = true;
      autoLogin = {
        enable = true;
        user = vars.user;
      };
      defaultSession = "steam";
    };

    systemd.user.services.steam-idle-sleep = lib.mkIf cfg.autoStartSteam {
      description = "Sleep after 15min idle in Steam session";
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

    systemd.user.services.cec-wake-tv = {
      description = "Wake TV and switch to PC input via CEC on Steam session start";
      partOf = ["steam-session.target"];
      wantedBy = ["steam-session.target"];
      serviceConfig = {
        Type = "oneshot";
        ExecStart = cecWakeScript;
      };
    };
  };
}
