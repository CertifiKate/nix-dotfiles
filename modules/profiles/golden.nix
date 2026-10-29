#
# Golden images to be pushed to Incus
# Contain nothing interesting except SSH and pre-setup users
#
{
  inputs,
  config,
  ...
}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."modules/profiles/golden" = {
    pkgs,
    lib,
    ...
  }: {
    nix.settings.trusted-users = [
      "server_admin"
      "deploy_user"
    ];

    environment.systemPackages = with pkgs; [
      ranger
      btop
      python3
    ];

    services.openssh.enable = true;

    # Lets Incus control the golden image (useful for setting IP/Hostname prior to actually setting up)
    services.cloud-init.enable = true;
    services.cloud-init.network.enable = true;
    services.cloud-init.settings = {
      manage_etc_hosts = true;
      preserve_hostname = false;
    };

    networking.useDHCP = lib.mkForce true;
    networking.useNetworkd = lib.mkForce false;
    systemd.network.enable = lib.mkForce false;
    networking.hostName = lib.mkForce "";

    services.resolved.enable = false;
    networking.nameservers = ["1.1.1.1" "8.8.8.8"];

    services.getty.autologinUser = "server_admin";
  };

  # The image's /etc/nixos/configuration.nix only picks up nixpkgs modules passed directly to
  # nixosSystem, so name the instance type explicitly
  configurations.nixos = {
    golden-incus-vm.module = {
      imports = [
        nixos."modules/profiles/golden"
        nixos."modules/profiles/server"
        "${inputs.nixpkgs}/nixos/modules/virtualisation/incus-virtual-machine.nix"
      ];
      installer.cloneConfigIncludes = ["<nixpkgs/nixos/modules/virtualisation/incus-virtual-machine.nix>"];
      nixpkgs.hostPlatform = {system = "x86_64-linux";};
      system.nixos.distroName = "NixOS Golden VM";
      system.nixos.label = "golden-vm";
    };
    golden-lxc.module = {
      imports = [
        nixos."modules/profiles/golden"
        nixos."modules/profiles/server"
        "${inputs.nixpkgs}/nixos/modules/virtualisation/lxc-container.nix"
      ];
      installer.cloneConfigIncludes = ["<nixpkgs/nixos/modules/virtualisation/lxc-container.nix>"];
      nixpkgs.hostPlatform = {system = "x86_64-linux";};
      system.nixos.distroName = "NixOS Golden LXC";
      system.nixos.label = "golden-lxc";
    };
  };
}
