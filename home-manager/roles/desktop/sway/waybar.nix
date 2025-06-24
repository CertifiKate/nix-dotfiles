{
  pkgs,
  nix-colors,
  config,
  ...
}: {
  programs.waybar = {
    enable = true;
    settings = {
      mainBar = {
        layer = "top";
        position = "top";
        height = 30;
        output = [
          "eDP-1"
        ];

        # "sway/window"
        modules-left = ["custom/menu-button"];
        modules-center = ["sway/workspaces"];
        modules-right = ["clock" "battery"];

        "custom/menu-button" = {
          format = "O";
        };

        "clock" = {
          format = "{:%I:%M}";
        };

        # "sway/workspaces" = {
        #   format = ""
        # };
      };
    };

    style = ''
      window#waybar {
          background: #${config.colorScheme.palette.base00};
          background: transparent;
          transition-property: background-color;
      }

      #workspaces button {
          background: none;
          color: #${config.colorScheme.palette.base04};
          margin-top: 5px;
          margin-bottom: 5px;
          padding-left: 10px;
          padding-right: 10px;
          font-weight: bolder;
      }

      #workspaces button.focused {
          text-shadow: transparent;
          border: 1px solid #${config.colorScheme.palette.base04};
          border-radius: 30px;
          background: #${config.colorScheme.palette.base04};
          color: #${config.colorScheme.palette.base00};
          transition: all 0.3s ease-in-out;
          animation: gradient_f 20s ease-in-out infinite, gradient 10s ease infinite;
          font-weight: bolder;
      }


      /*#battery {
        background: #${config.colorScheme.palette.base0E};
      }

      #clock {
        background: #${config.colorScheme.palette.base0C};
      }

      #workspaces {
        background: #${config.colorScheme.palette.base09};
      }*/

      #custom-menu-button {
        padding-left: 20px;
        padding-right: 20px;
      }

      /* Lean right */
      #custom-menu-button,
      #workspaces {
        border-radius: 25px 10px;
      }

      /* Lean left*/
      #battery,
      #clock {
        border-radius: 10px 25px;
      }

      #clock,
      #battery,
      #custom-menu-button,
      #workspaces {
        background: #${config.colorScheme.palette.base00};
        color: #${config.colorScheme.palette.base05};
        opacity: 0.75;
        padding-left: 10px;
        padding-right: 10px;
        margin-top: 5px;
        margin-bottom: 5px;

        margin-left: 10px;
        margin-right: 10px;
        font-weight: bolder;
      }

    '';
  };
}
