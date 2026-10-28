{
  inputs,
  vars,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
in {
  imports = [
    ../base
    ./remote-build.nix
  ];

  sops = {
    defaultSopsFile = "${secretsPath}/secrets/home-manager.yaml";

    age = {
      keyFile = "/home/${vars.user}/.config/sops-age.txt";
      generateKey = false;
    };
  };

  CertifiKate.remoteBuilders = {
    enable = true;
    buildHosts = [
      "build-01.srv"
      "build-02.srv"
    ];
  };
}
