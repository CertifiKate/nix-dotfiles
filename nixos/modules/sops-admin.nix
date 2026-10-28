{
  inputs,
  vars,
  ...
}: let
  secretsPath = toString inputs.nix-secrets;
in {
  sops.secrets."${vars.user}_sops_admin_key" = {
    sopsFile = "${secretsPath}/secrets/sops-admin.yaml";
    owner = vars.user;
    mode = "0400";
    path = "/home/${vars.user}/.config/sops/age/keys.txt";
  };
}
