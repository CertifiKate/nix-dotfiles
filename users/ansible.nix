{
  users.users.ansible = {
    isNormalUser = true;
    extraGroups = ["wheel"];
    hashedPassword = "";
    openssh.authorizedKeys.keys = [
      "ecdsa-sha2-nistp521 AAAAE2VjZHNhLXNoYTItbmlzdHA1MjEAAAAIbmlzdHA1MjEAAACFBAAVuLf+Dc1JkDNX3+STIL9W5kasHu09YVW1vI/S5z5g4HbGiKbGTtvkKCYjk5hHabRIALxhsx4N0lCxeOrCmSwWQABA/EQGSEccl1er+XP+9o/SrB8/do/emIg6zEzu5XhL4RT3Y2I6Rf5RewkISlcXD1mxgkbVo+qemzSYMdBD81nWJg== ansible key"
    ];
  };

  # Enable passwordless sudo for ansible user
  # TODO: Restrict commands - how does that work with ansible? I believe it just runs `python3 x`
  security.sudo = {
    extraRules = [
      {
        users = ["ansible"];
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
