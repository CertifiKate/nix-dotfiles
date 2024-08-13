# Defines the groups so our mounted drives don't have permission issues
{
  users = {
    groups.media = {
      # Manually specify gid to ensure it's consistent across hosts (media-01/media-02)
      gid = 150;
    };
  };
}
