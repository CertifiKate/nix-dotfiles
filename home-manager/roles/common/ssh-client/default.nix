{
  programs.ssh = {
    enable = true;
    addKeysToAgent = "yes";
    forwardAgent = true;
  };

  # Github ssh config
  programs.ssh.matchBlocks = {
    "github.com" = {
      identityFile = [
        "/home/kate/.ssh/id_ed25519-github"
      ];
    };
  };
}