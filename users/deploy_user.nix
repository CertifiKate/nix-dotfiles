{
  users.users."deploy_user" = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAINgK8sohwDKF5YjXZfUZNqEBWajFWfwQWCmZij5kxm/W nix deploy key"
    ];
  };

  security.sudo = {
    extraRules = [
      {
        users = ["deploy_user"];
        commands = [
          {
            command = "ALL";
            options = ["NOPASSWD"];
          }
        ];
      }
    ];
  };
}
