# Defines the groups so our mounted drives don't have permission issues
{
  flake.modules.nixos."roles/server/common/media-group" = {
    users = {
      groups.media = {
        # Manually specify gid to ensure it's consistent across hosts (media-01/media-02)
        gid = 150;
      };
    };
  };
}
