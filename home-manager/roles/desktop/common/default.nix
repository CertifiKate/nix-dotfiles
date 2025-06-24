{
  imports = [
    ./apps
  ];

  # Setup user profile pic
  home.file.".face" = {
    source = ./face.png;
  };
}
