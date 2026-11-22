{inputs, ...}: {
  flake.modules.homeManager."roles/physical/desktop/apps" = {
    config,
    lib,
    pkgs,
    ...
  }: let
    inherit (config.CertifiKate) theme look;
    inherit (config.colorScheme) palette variant slug name;
    c = lib.mapAttrs (_: hex: "#${hex}") palette;

    themeJson = builtins.toJSON {
      inherit name;
      type = variant;
      colors = {
        "foreground" = c.base05;
        "descriptionForeground" = c.base04;
        "focusBorder" = c.base0D;
        "widget.border" = c.base02;
        "editor.background" = c.base00;
        "editor.foreground" = c.base05;
        "editor.lineHighlightBackground" = c.base01;
        "editor.selectionBackground" = c.base02;
        "editor.findMatchHighlightBackground" = "${c.base0A}40";
        "editorLineNumber.foreground" = c.base03;
        "editorLineNumber.activeForeground" = c.base05;
        "editorIndentGuide.background1" = c.base02;
        "editorWidget.background" = c.base01;
        "editorGroupHeader.tabsBackground" = c.base01;
        "editorError.foreground" = c.base08;
        "editorWarning.foreground" = c.base0A;
        "tab.inactiveBackground" = c.base01;
        "tab.activeBorderTop" = c.base0D;
        "tab.border" = c.base01;
        "titleBar.activeBackground" = c.base01;
        "titleBar.inactiveBackground" = c.base01;
        "activityBar.background" = c.base01;
        "activityBar.activeBorder" = c.base0D;
        "activityBarBadge.background" = c.base0D;
        "activityBarBadge.foreground" = c.base00;
        "sideBar.background" = c.base01;
        "panel.border" = c.base02;
        "statusBar.background" = c.base01;
        "statusBar.foreground" = c.base04;
        "statusBar.noFolderBackground" = c.base01;
        "statusBar.debuggingBackground" = c.base09;
        "statusBar.debuggingForeground" = c.base00;
        "list.activeSelectionBackground" = c.base02;
        "list.inactiveSelectionBackground" = c.base02;
        "list.hoverBackground" = c.base01;
        "input.background" = c.base00;
        "input.border" = c.base02;
        "dropdown.background" = c.base01;
        "button.background" = c.base0D;
        "button.foreground" = c.base00;
        "button.hoverBackground" = c.base0C;
        "badge.background" = c.base0D;
        "badge.foreground" = c.base00;
        "textLink.foreground" = c.base0D;
        "textLink.activeForeground" = c.base0C;
        "gitDecoration.modifiedResourceForeground" = c.base0A;
        "gitDecoration.untrackedResourceForeground" = c.base0B;
        "gitDecoration.deletedResourceForeground" = c.base08;
        "terminal.ansiBlack" = c.base01;
        "terminal.ansiRed" = c.base08;
        "terminal.ansiGreen" = c.base0B;
        "terminal.ansiYellow" = c.base0A;
        "terminal.ansiBlue" = c.base0D;
        "terminal.ansiMagenta" = c.base0E;
        "terminal.ansiCyan" = c.base0C;
        "terminal.ansiWhite" = c.base05;
        "terminal.ansiBrightBlack" = c.base03;
        "terminal.ansiBrightRed" = c.base08;
        "terminal.ansiBrightGreen" = c.base0B;
        "terminal.ansiBrightYellow" = c.base0A;
        "terminal.ansiBrightBlue" = c.base0D;
        "terminal.ansiBrightMagenta" = c.base0E;
        "terminal.ansiBrightCyan" = c.base0C;
        "terminal.ansiBrightWhite" = c.base07;
      };
      tokenColors = lib.mapAttrsToList (scope: settings: {inherit scope settings;}) {
        "comment, punctuation.definition.comment" = {
          foreground = c.base03;
          fontStyle = "italic";
        };
        "string, punctuation.definition.string" = {foreground = c.base0B;};
        "constant.numeric, constant.language, constant.character, support.constant" = {foreground = c.base09;};
        "keyword, storage, keyword.control" = {foreground = c.base0E;};
        "keyword.operator, punctuation" = {foreground = c.base05;};
        "variable, variable.parameter, entity.name.tag" = {foreground = c.base08;};
        "entity.name.function, support.function, meta.function-call" = {foreground = c.base0D;};
        "entity.name.type, entity.name.class, support.type, support.class" = {foreground = c.base0A;};
        "entity.other.attribute-name, variable.other.property, meta.object-literal.key" = {foreground = c.base0D;};
        "string.regexp, constant.character.escape" = {foreground = c.base0C;};
      };
    };

    themeExtension = let
      publisher = "certifikate";
      extName = "${slug}-theme";
      id = "${publisher}.${extName}";
    in
      pkgs.runCommand id {
        version = "1.0.0";
        passthru = {
          vscodeExtUniqueId = id;
          vscodeExtPublisher = publisher;
          vscodeExtName = extName;
        };
        packageJson = builtins.toJSON {
          inherit publisher;
          name = extName;
          version = "1.0.0";
          engines.vscode = "*";
          contributes.themes = [
            {
              label = name;
              uiTheme =
                if variant == "dark"
                then "vs-dark"
                else "vs";
              path = "./theme.json";
            }
          ];
        };
        inherit themeJson;
        passAsFile = ["packageJson" "themeJson"];
      } ''
        dir=$out/share/vscode/extensions/${id}
        mkdir -p $dir
        cp $packageJsonPath $dir/package.json
        cp $themeJsonPath $dir/theme.json
      '';
  in {
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
        extensions = with pkgs.vscode-extensions;
          [
            kamadorueda.alejandra
            jnoortheen.nix-ide
            anthropic.claude-code
            ms-vscode-remote.remote-ssh
            ms-vscode-remote.remote-containers
            coder.coder-remote
            inputs.nix-vscode-extensions.extensions.${pkgs.stdenv.hostPlatform.system}.vscode-marketplace.datakurre.devenv
          ]
          ++ lib.optional (theme != null) themeExtension;
        userSettings =
          lib.optionalAttrs (theme != null) {
            "workbench.colorTheme" = name;
            "editor.fontFamily" = "'${look.fonts.mono.name}', monospace";
            "editor.fontLigatures" = true;
            "terminal.integrated.fontFamily" = "'${look.fonts.mono.name}', monospace";
          }
          // {
            "git.autofetch" = true;
            "git.confirmSync" = false;
            "terminal.integrated.defaultProfile.linux" = "zsh";
            "nix.enableLanguageServer" = true;
            "nix.serverPath" = "nixd";
            # The devenv extension prepends /run/current-system/sw/bin to PATH, shadowing the setuid sudo wrapper
            "devenv.path.nixBinPaths" = ["/run/wrappers/bin"];
            # Collapsible secondary sidebar, rather than a tab in its own locked editor group
            "claudeCode.preferredLocation" = "sidebar";
            "claudeCode.lockEditorGroups" = false;
            "chat.disableAIFeatures" = true;
            "telemetry.telemetryLevel" = "off";
            "workbench.enableExperiments" = false;
            "workbench.startupEditor" = "none";
            "workbench.tips.enabled" = false;
            "workbench.welcomePage.walkthroughs.openOnInstall" = false;
            "extensions.autoUpdate" = "off";
            "extensions.autoCheckUpdates" = false;
            "diffEditor.renderSideBySide" = true;
            "diffEditor.useInlineViewWhenSpaceIsLimited" = false;
          };
        enableUpdateCheck = false;
      };
    };
  };
}
