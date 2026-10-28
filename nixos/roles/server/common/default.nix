{...}: {
  # Add in some additional routes for when they aren't available in other modules (ie. Home Assistant)
  CertifiKate.roles.server.routes.home = {
    host = "home";
    dest = "http://home-02.srv";
    rules = [
      {
        policy = "bypass";
      }
    ];
  };
}
