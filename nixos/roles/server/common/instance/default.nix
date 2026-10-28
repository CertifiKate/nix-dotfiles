# Common config for Incus instances (LXCs and VMs), as opposed to the Incus hypervisors
{vars, ...}: {
  nixpkgs.system = "x86_64-linux";
}
