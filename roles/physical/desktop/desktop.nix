#
# Common home-manager config for any graphical desktop
#
{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager."roles/physical/desktop" = {
    imports = [
      homeManager."roles/physical/desktop/apps"
    ];

    # Setup user profile pic
    home.file.".face" = {
      source = ./face.png;
    };
  };
}
