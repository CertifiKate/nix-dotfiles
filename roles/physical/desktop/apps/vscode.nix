{inputs, ...}: {
  flake.modules.homeManager."roles/physical/desktop/apps" = {
    config,
    lib,
    pkgs,
    ...
  }: {
    # The Coder extension rewrites ~/.ssh/config to add its include, replacing the symlink.
    # Include it ourselves and overwrite rather than back up, so activation never gets stuck
    programs.ssh.includes = ["~/.local/share/coder.coder-remote/ssh/*.conf"];
    home.file = lib.mkIf config.programs.ssh.enable {".ssh/config".force = true;};

    home.packages = with pkgs; [
      nixd
      # alejandra
    ];

    programs.vscode = {
      enable = true;
      mutableExtensionsDir = true;
      profiles.default = {
        extensions = with pkgs.vscode-extensions; [
          kamadorueda.alejandra
          jnoortheen.nix-ide
          ms-vscode-remote.remote-ssh
          ms-vscode-remote.remote-containers
          coder.coder-remote
          inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace.datakurre.devenv
        ];
        userSettings = {
          "git.autofetch" = true;
          "git.confirmSync" = false;
          "terminal.integrated.defaultProfile.linux" = "zsh";
          "nix.enableLanguageServer" = true;
          "nix.serverPath" = "nixd";
          "claudeCode.preferredLocation" = "panel";
          "chat.disableAIFeatures" = true;
          "telemetry.telemetryLevel" = "off";
          "workbench.enableExperiments" = false;
          "workbench.startupEditor" = "none";
          "workbench.tips.enabled" = false;
          "workbench.welcomePage.walkthroughs.openOnInstall" = false;
          "extensions.autoUpdate" = false;
          "extensions.autoCheckUpdates" = false;
        };
        enableUpdateCheck = false;
      };
    };
  };
}
