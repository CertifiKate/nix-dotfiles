{config, ...}: let
  inherit (config.meta) user;
  inherit (config.flake.modules) nixos;
in {
  configurations.nixos.comet.module = {
    lib,
    pkgs,
    ...
  }: {
    imports = [
      nixos."modules/users/deploy-user"
    ];

    nix.settings.trusted-users = ["deploy_user"];

    environment.variables = {
      NIX_FLAKE_PATH = lib.mkForce "/home/${user}/source/nix-dotfiles";
    };

    services.openssh = {
      enable = true;
      settings.PasswordAuthentication = false;
      settings.KbdInteractiveAuthentication = false;
      settings.PermitRootLogin = "no";
    };

    boot.loader.systemd-boot.enable = true;
    boot.loader.efi.canTouchEfiVariables = true;
    boot.loader.timeout = 0;

    boot.kernelPackages = pkgs.linuxPackages_latest;

    systemd.services.NetworkManager-wait-online.enable = false;

    zramSwap.enable = true;

    services.logind.settings.Login = {
      "HandlePowerKey" = "suspend";
    };

    hardware.bluetooth = {
      enable = true;
      powerOnBoot = true;
    };
  };
}
