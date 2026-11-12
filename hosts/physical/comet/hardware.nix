{inputs, ...}: {
  configurations.nixos.comet.module = {
    imports = [inputs.nixos-hardware.nixosModules.gpd-pocket-3];

    boot.kernelParams = ["fbcon=nodefer"];

    environment.etc."libwacom/gpd-pocket-3.tablet".text = ''
      [Device]
      Name=GPD Pocket 3
      Class=ISDV4
      DeviceMatch=i2c|27c6|0113
      Width=172
      Height=108
      IntegratedIn=Display;System;
      Styli=@generic-no-eraser;

      [Features]
      Stylus=true
      Touch=true
    '';

    hardware.enableRedistributableFirmware = true;

    services.thermald.enable = true;

    services.fwupd.enable = true;
  };
}
