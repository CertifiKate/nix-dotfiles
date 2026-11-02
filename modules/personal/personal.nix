#
# Personal (ie. not work) user setup - git identity
#
{config, ...}: let
  inherit (config.flake.modules) homeManager;
in {
  flake.modules.homeManager."modules/personal" = {
    imports = [homeManager."modules/home-manager/git"];

    programs.git.settings.user = {
      name = "CertifiKate";
      email = "131977850+CertifiKate@users.noreply.github.com";
    };
  };
}
