# Incus VM instance, as opposed to the Incus hypervisors
{
  flake.modules.nixos."roles/server/instance/vm" = {modulesPath, ...}: {
    imports = ["${modulesPath}/virtualisation/incus-virtual-machine.nix"];
    nixpkgs.system = "x86_64-linux";
  };
}
