# Imported by path, so roles that both pull in the apps module don't declare the options twice
{
  config,
  lib,
  pkgs,
  ...
}: let
  cfg = config.CertifiKate;
  look = cfg.look;

  themes = {
    monet = import ./_monet.nix pkgs;
  };

  named = extra:
    lib.types.submodule {
      options =
        {
          name = lib.mkOption {type = lib.types.str;};
          package = lib.mkOption {type = lib.types.package;};
        }
        // extra;
    };
in {
  options.CertifiKate = {
    theme = lib.mkOption {
      type = with lib.types; nullOr (enum (lib.attrNames themes));
      default = null;
      description = "Desktop theme, from themes/";
    };
    look = {
      wallpaper = lib.mkOption {type = lib.types.path;};
      fonts = {
        sans = lib.mkOption {type = named {};};
        mono = lib.mkOption {type = named {};};
      };
      cursor = lib.mkOption {type = named {size = lib.mkOption {type = lib.types.int;};};};
      icons = lib.mkOption {type = named {};};
    };
  };

  config = lib.mkIf (cfg.theme != null) (let
    # mkIf still walks the attrs below to push mkDefault down, so this can't fail without a theme
    theme = themes.${toString cfg.theme} or {colorScheme = {};};
  in {
    colorScheme = lib.mkDefault theme.colorScheme;
    CertifiKate.look = lib.mkDefault (removeAttrs theme ["colorScheme"]);

    home.packages = [look.fonts.sans.package look.fonts.mono.package];
    fonts.fontconfig = {
      enable = true;
      defaultFonts = {
        sansSerif = [look.fonts.sans.name];
        monospace = [look.fonts.mono.name];
      };
    };

    home.pointerCursor = {
      inherit (look.cursor) name package size;
      gtk.enable = true;
    };
    gtk = {
      enable = true;
      iconTheme = {inherit (look.icons) name package;};
    };
  });
}
