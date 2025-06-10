{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd
    # alejandra
  ];

  programs.vscode = {
    enable = true;
    profiles.default = {
      extensions = with pkgs.vscode-extensions; [
        kamadorueda.alejandra
        jnoortheen.nix-ide
        ms-vscode-remote.remote-ssh
        streetsidesoftware.code-spell-checker
        ms-dotnettools.csharp
        ms-dotnettools.csdevkit
        ms-dotnettools.vscode-dotnet-runtime
        ms-vscode-remote.remote-containers
        ms-azuretools.vscode-docker
      ];
      userSettings = {
        "git.autofetch" = true;
        "git.confirmSync" = false;
        "terminal.integrated.defaultProfile.linux" = "zsh";
        "nix.enableLanguageServer" = true;
        "nix.serverPath" = "nixd";
      };
      enableUpdateCheck = false;
    };

    mutableExtensionsDir = true;
  };
}
