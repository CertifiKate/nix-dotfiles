#
# Secret-free git setup for anywhere, with no identity as that depends on whose machine it is
# See modules/personal for ours
#
{
  flake.modules.homeManager."modules/home-manager/git" = {
    programs.git = {
      enable = true;
      settings.init.defaultBranch = "main";
    };
  };
}
