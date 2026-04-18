{modulesPath, ...}: let
  server_name = "incus-01";
in {
  imports = [
    ./hardware-configuration.nix
    ./system-configuration.nix
  ];

  networking.hostName = server_name;

  CertifiKate.roles.server.incus_host = {
    enable = true;
    serverName = server_name;
    serverAddress = "192.168.10.201";
    external_interfaces = "ens18";
  };
  nixpkgs.system = "x86_64-linux";
}
