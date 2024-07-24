{ inputs, ... }:
{
  imports = [ inputs.nix-minecraft.nixosModules.minecraft-servers ];
  nixpkgs.overlays = [ inputs.nix-minecraft.overlay ];


  services.minecraft-servers.enable = true;
  # TODO: Actually get this working
}