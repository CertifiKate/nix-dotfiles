{pkgs, ...}: {
  home.packages = with pkgs; [
    nixd
    # alejandra
  ];

  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      # bbenoist.nix
      kamadorueda.alejandra
      jnoortheen.nix-ide
    ];

    userSettings = {
      "git.autofetch" = true;
      "git.confirmSync" = false;
      "terminal.integrated.defaultProfile.linux" = "zsh";
      "nix.enableLanguageServer" = true;
      "nix.serverPath" = "nixd";
      # "nix.formatterPath" =  ["alejandra"];
    };
  };
}
