# Basic config adapted from https://github.com/IvarWithoutBones/dotfiles/blob/main/home-manager/modules/linux/i3-sway/keybindings.nix
{
  pkgs,
  mod,
  workspaces,
}: {
  "${mod}+Return" = "exec alacritty";
  #   "${mod}+Return" = "exec --no-startup-id ${config.home.sessionVariables.TERMINAL}";
  "${mod}+Tab" = "exec ${pkgs.wofi}/bin/wofi --show run";

  # Window Management
  "${mod}+q" = "kill";
  "${mod}+f" = "fullscreen toggle";
  "${mod}+Shift+space" = "floating toggle";

  # Layouts
  "${mod}+s" = "layout stacking";
  "${mod}+w" = "layout tabbed";
  "${mod}+e" = "layout toggle split";

  # Workspace management
  "${mod}+1" = "workspace ${workspaces.ws1}";
  "${mod}+2" = "workspace ${workspaces.ws2}";
  "${mod}+3" = "workspace ${workspaces.ws3}";
  "${mod}+4" = "workspace ${workspaces.ws4}";
  "${mod}+5" = "workspace ${workspaces.ws5}";
  "${mod}+6" = "workspace ${workspaces.ws6}";
  "${mod}+7" = "workspace ${workspaces.ws7}";
  "${mod}+8" = "workspace ${workspaces.ws8}";
  "${mod}+9" = "workspace ${workspaces.ws9}";
  "${mod}+0" = "workspace ${workspaces.ws10}";

  "${mod}+Shift+1" = "move container to workspace ${workspaces.ws1}";
  "${mod}+Shift+2" = "move container to workspace ${workspaces.ws2}";
  "${mod}+Shift+3" = "move container to workspace ${workspaces.ws3}";
  "${mod}+Shift+4" = "move container to workspace ${workspaces.ws4}";
  "${mod}+Shift+5" = "move container to workspace ${workspaces.ws5}";
  "${mod}+Shift+6" = "move container to workspace ${workspaces.ws6}";
  "${mod}+Shift+7" = "move container to workspace ${workspaces.ws7}";
  "${mod}+Shift+8" = "move container to workspace ${workspaces.ws8}";
  "${mod}+Shift+9" = "move container to workspace ${workspaces.ws9}";
  "${mod}+Shift+0" = "move container to workspace ${workspaces.ws10}";

  # Navigation
  "${mod}+h" = "focus left";
  "${mod}+l" = "focus right";
  "${mod}+k" = "focus up";
  "${mod}+j" = "focus down";
  "${mod}+Shift+h" = "move left";
  "${mod}+Shift+l" = "move right";
  "${mod}+Shift+k" = "move up";
  "${mod}+Shift+j" = "move down";

  # "SUPER, q, killactive"

  # "SUPER, s, togglesplit"
  # "SUPER, f, fullscreen, 1"
  # "SUPERSHIFT, f, fullscreen, 0"
  # "SUPERSHIFT, space, togglefloating"

  # # Resize windows
  # "SUPER,minus,splitratio,-0.2"
  # "SUPERSHIFT,minus,splitratio,-0.1"
  # "SUPER,equal,splitratio,0.2"
  # "SUPERSHIFT,equal,splitratio,0.1"

  # # Start applications
  # # "$mod, F, exec, firefox"
  # "SUPER, Return, exec, kgx"
  # "SUPER, E, exec, code"
}
# ]
# ++
# ++
# # Move window to workspace
# (map (n: "SUPERSHIFT,${n},movetoworkspacesilent,name:${n}") workspaces)
# ++
# # Move focus
# (lib.mapAttrsToList (key: direction: "SUPER,${key},movefocus,${direction}") directions)
# ++
# # Swap windows
# (lib.mapAttrsToList (key: direction: "SUPERSHIFT,${key},swapwindow,${direction}") directions)
# ++
# # Move windows
# (lib.mapAttrsToList (
#     key: direction: "SUPERCONTROL,${key},movewindoworgroup,${direction}"
#   )
#   directions);

