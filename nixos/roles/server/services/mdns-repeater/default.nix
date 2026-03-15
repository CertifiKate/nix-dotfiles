{
  config,
  lib,
  ...
}: {
  config = lib.mkMerge [
    (lib.mkIf config.CertifiKate.roles.server.mdns_repeater.enable {
      services.avahi = {
        enable = true;
        reflector = true;
        allowInterfaces = [
          "eth0"
          "eth1"
        ];
      };
    })
  ];
}
