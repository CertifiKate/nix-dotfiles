{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd
    # alejandra
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      kamadorueda.alejandra
      jnoortheen.nix-ide
      ms-vscode-remote.remote-ssh
      streetsidesoftware.code-spell-checker
    ];

    enableUpdateCheck = false;
    mutableExtensionsDir = false;

    userSettings = {
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
    };
  };
}
