#
# Profile for physical machines (laptop, desktop, HTPC)
#
{config, ...}: let
  inherit (config.flake.modules) nixos;
in {
  flake.modules.nixos."modules/profiles/physical" = {pkgs, ...}: {
    # All Physical machines should use home manager
    imports = [
      nixos."modules/profiles/common"
      nixos."modules/home-manager"
    ];

    # Yubikey
    services.pcscd.enable = true;

    # Enable networking
    networking.networkmanager.enable = true;

    # Select internationalisation properties.
    i18n.defaultLocale = "en_AU.UTF-8";

    i18n.extraLocaleSettings = {
      LC_ADDRESS = "en_AU.UTF-8";
      LC_IDENTIFICATION = "en_AU.UTF-8";
      LC_MEASUREMENT = "en_AU.UTF-8";
      LC_MONETARY = "en_AU.UTF-8";
      LC_NAME = "en_AU.UTF-8";
      LC_NUMERIC = "en_AU.UTF-8";
      LC_PAPER = "en_AU.UTF-8";
      LC_TELEPHONE = "en_AU.UTF-8";
      LC_TIME = "en_AU.UTF-8";
    };

    # Configure keymap in X11
    services.xserver.xkb = {
      layout = "au";
      variant = "";
    };

    # # Enable CUPS to print documents.
    services.printing.enable = true;

    # Enable sound with pipewire.
    security.rtkit.enable = true;

    environment.systemPackages = with pkgs; [
      alsa-utils
      lm_sensors
    ];

    programs.nix-ld.enable = true;

    # Auto upgrade from latest pushed flake versions
    system.autoUpgrade = {
      enable = true;
      flake = "github:CertifiKate/nix-dotfiles";
      operation = "boot";
      dates = "hourly";
      randomizedDelaySec = "10min";
      persistent = true;
    };

    # Only auto upgrade when we can see the build machines
    systemd.services.nixos-upgrade.serviceConfig.ExecCondition = pkgs.writeShellScript "on-home-network" ''
      ${pkgs.iputils}/bin/ping -c1 -W2 build-01.srv >/dev/null
    '';

    # Read-only deploy key so root can fetch the private nix-secrets input
    sops.secrets."nix_secrets_ro_deploy_key".path = "/root/.ssh/id_ed25519_nix_secrets";
    programs.ssh = {
      knownHosts."github.com".publicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIOMqqnkVzrm0SdG6UOoqKLsabgH5C9okWi0dh2l9GKJl";
      extraConfig = ''
        Match host github.com localuser root
          IdentityFile /root/.ssh/id_ed25519_nix_secrets
          IdentitiesOnly yes
      '';
    };

    # Enable our boot loading animation
    boot = {
      plymouth = {
        enable = true;
        theme = "circle_flow";
        themePackages = with pkgs; [
          (adi1090x-plymouth-themes.override {
            selected_themes = [
              "circle_flow"
              "colorful"
              "colorful_sliced"
              "double"
              "polaroid"
            ];
          })
        ];
      };

      # Enable "Silent Boot"
      consoleLogLevel = 0;
      kernelParams = [
        "quiet"
        "splash"
        "boot.shell_on_fail"
        "loglevel=3"
        "rd.systemd.show_status=false"
        "rd.udev.log_level=3"
        "udev.log_priority=3"
      ];
    };
  };
}
