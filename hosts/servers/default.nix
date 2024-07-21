# TODO: Enable ssh? Or do this in a role?

# Essentially we just want to de-dupe roles/lxcs and roles/vms
{ pkgs, ...}:
{

  # For ansible support
  #TODO Do we even really need this anymore? Just for provisioning? Can it be moved to the golden image config and removed later?
  environment.systemPackages = with pkgs; [
    python3
  ];

  services.openssh.enable = true;

}