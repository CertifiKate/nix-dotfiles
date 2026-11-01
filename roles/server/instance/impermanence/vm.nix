#
# Impermanence for Incus VM instances
#
# VMs have an initrd so this is the standard approach. The golden image's disk already has /nix at
# the top level, so the rest of the old root is just left behind in /disk
#
{inputs, ...}: {
  flake.modules.nixos."roles/server/instance/impermanence/vm" = {
    config,
    lib,
    ...
  }: let
    cfg = config.CertifiKate.persist;
  in {
    imports = [inputs.impermanence.nixosModules.impermanence];

    config = lib.mkIf (cfg.enable && cfg.backend == "vm") {
      fileSystems = {
        "/" = lib.mkForce {
          fsType = "tmpfs";
          options = ["mode=0755" "size=1G"];
        };
        "/disk" = {
          device = "/dev/disk/by-label/nixos";
          fsType = "ext4";
          autoResize = true;
          neededForBoot = true;
        };
        "/nix" = {
          device = "/disk/nix";
          fsType = "none";
          options = ["bind"];
          neededForBoot = true;
        };
        "/persist" = {
          device = "/disk/persist";
          fsType = "none";
          options = ["bind"];
          neededForBoot = true;
        };
      };

      environment.persistence."/persist/data" = {
        hideMounts = true;
        directories = cfg.directories ++ cfg.localDirectories;
        inherit (cfg) files;
      };
    };
  };
}
