{
  modulesPath,
  pkgs,
  ...
}: {
  networking.nftables.enable = true;
  # Core configuration, shared across all cluster instances. Overrides must be done on a per-host level
  virtualisation.incus = {
    enable = true;
    package = pkgs.incus;
    ui = {
      enable = true;
    };
    preseed = {
      core.https_address = ":8443";
    };
  };

  nixpkgs.system = "x86_64-linux";
}
