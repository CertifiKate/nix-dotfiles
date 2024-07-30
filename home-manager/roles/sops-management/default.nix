{ inputs, pkgs, ...}:
{
  # TODO: Add sops age admin key
  home.packages = with pkgs; [
    sops
    age
  ];
}