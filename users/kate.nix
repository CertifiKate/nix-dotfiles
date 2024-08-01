{
  config,
  lib,
  ...
}: {
  sops.secrets."users_kate_password_hash".neededForUsers = true;

  users.users.kate = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIGo9WY7TLTIFt52azw9w8+JXUATPjIAO17ktKDuWguMqAAAADHNzaDprYXRlQHNzaA== kate@yubikey5c"
      "sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIP4/ABrztYqDH1yZR0vIxUITa/M+CdaodvztkGZFkWaYAAAADHNzaDpLYXRlIFNTSA== kate@yubikey5"
    ];
    hashedPasswordFile = config.sops.secrets."users_kate_password_hash".path;
  };
}
