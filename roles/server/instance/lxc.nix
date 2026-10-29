# Incus LXC instance, as opposed to the Incus hypervisors
{
  flake.modules.nixos."roles/server/instance/lxc" = {modulesPath, ...}: {
    imports = ["${modulesPath}/virtualisation/lxc-container.nix"];
    nixpkgs.system = "x86_64-linux";
  };
}
