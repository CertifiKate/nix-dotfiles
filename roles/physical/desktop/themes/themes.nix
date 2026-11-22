{inputs, ...}: {
  flake.modules.homeManager."roles/physical/desktop/apps".imports = [
    inputs.nix-colors.homeManagerModules.default
    ./_look.nix
  ];
}
