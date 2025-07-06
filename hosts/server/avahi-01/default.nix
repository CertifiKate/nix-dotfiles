{...}: {
  imports = [
    ../../../nixos/roles/server/avahi
  ];

  networking.hostName = "avahi-01";
}
