{pkgs, ...}: {
  systemd.user.services.steam-autostart = {
    Unit = {
      Description = "Start Steam in desktop mode on login";
      After = "graphical-session.target";
    };
    Install.WantedBy = ["graphical-session.target"];
    Service = {
      Environment = ["SDL_VIDEODRIVER=x11" "GDK_BACKEND=x11"];
      ExecStart = "${pkgs.steam}/bin/steam -silent -pipewire";
      Restart = "on-failure";
      RestartSec = "3s";
    };
  };
}
