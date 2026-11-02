{inputs, ...}: {
  configurations.nixos.aurora.module = {
    imports = with inputs.nixos-hardware.nixosModules; [
      lenovo-thinkpad
      common-pc-ssd
      common-cpu-amd-pstate
      common-gpu-amd
    ];

    # Carried over from the E14 profile; backlight is amdgpu_bl1
    boot.kernelParams = ["acpi_backlight=native"];

    # acpi-tad registers as rtc0 ahead of rtc_cmos, but its alarm can't wake from
    # s2idle, so rtcwake and suspend-then-hibernate's timer never fire
    boot.blacklistedKernelModules = ["acpi_tad"];

    # Firmware updates via LVFS: `fwupdmgr refresh && fwupdmgr get-updates`
    services.fwupd.enable = true;
  };
}
