#
# Every pinned version lives here. Read them from the flake-parts `config` (ie. `config.meta.versions`)
#
{lib, ...}: {
  options.meta.versions = lib.mkOption {
    type = lib.types.attrsOf lib.types.str;
    description = "Pinned versions of container images";
  };

  config.meta.versions = {
    actualbudget = "26.10.0";
    calibre-web = "latest";
  };
}
