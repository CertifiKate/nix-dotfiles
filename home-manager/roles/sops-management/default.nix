{pkgs, ...}: {
  # The administration key itself is placed by nixos/modules/sops-admin.nix, so it stays out of
  # anything the shared home-manager key can decrypt
  home.packages = with pkgs; [
    sops
    age
  ];
}
