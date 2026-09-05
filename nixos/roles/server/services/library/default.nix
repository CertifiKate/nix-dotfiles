{pkgs, ...}: let
  calibre_dir = "/services/calibre-web";
  book_dir = "/data/Books";
in {
  environment.systemPackages = with pkgs; [
    python314
    python314Packages.python-ldap # Used by calibre-web for LDAP authentication
  ];

  virtualisation.oci-containers.containers = {
    calibre-web = {
      autoStart = true;
      image = "lscr.io/linuxserver/calibre-web:latest";
      ports = ["8083:8083"];
      volumes = [
        "${calibre_dir}/data:/config"
        "${book_dir}:/books"
      ];
    };
  };
}
