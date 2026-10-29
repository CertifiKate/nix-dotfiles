{inputs, ...}: {
  imports = [
    # Provides `flake.modules.<class>.<name>`, which every feature module contributes to
    inputs.flake-parts.flakeModules.modules
  ];

  systems = ["x86_64-linux"];

  perSystem = {pkgs, ...}: {
    formatter = pkgs.alejandra;
  };
}
