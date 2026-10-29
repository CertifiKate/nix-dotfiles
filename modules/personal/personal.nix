#
# Personal (ie. not work) user setup - git identity and SSH keys
#
{
  flake.modules.homeManager."modules/personal" = {
    # Configure our git config
    programs.git = {
      enable = true;
      settings = {
        user = {
          name = "CertifiKate";
          email = "131977850+CertifiKate@users.noreply.github.com";
        };
        init.defaultBranch = "main";
      };
    };
  };
}
