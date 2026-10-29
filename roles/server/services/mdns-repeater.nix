{
  flake.modules.nixos."roles/server/services/mdns-repeater" = {
    services.avahi = {
      enable = true;
      reflector = true;
      allowInterfaces = [
        "eth0"
        "eth1"
      ];
    };
  };
}
