{
  pkgs,
  lib,
  config,
  inputs,
  ...
}: {
  packages = [
    pkgs.git
    pkgs.terraform
    pkgs.incus
    pkgs.minio-client # S3 (incus storage buckets)
  ];

  scripts.incus-s3.exec = ''
    TERM=dumb MC_INSECURE=true mc "$@" incus/terraform
  '';

  # https://devenv.sh/languages/
  languages.terraform.enable = true;
}
