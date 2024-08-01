{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}: {
  services.avahi = {
    enable = true;
    reflector = true;
    allowInterfaces = [
      "eth0"
      "eth1"
    ];
  };
}
