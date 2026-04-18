{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  packages = [
    pkgs.git
    pkgs.terraform
    pkgs.incus
  ];

  # https://devenv.sh/languages/
  languages.terraform.enable = true;
}
