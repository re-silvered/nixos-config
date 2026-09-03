{ config, lib, pkgs, ... }:

{
  # GPU
  boot.initrd.kernelModules = [ "amdgpu" ];

  hardware.enableRedistributableFirmware = true;

  hardware = {
    graphics = {
      enable = true;
      enable32Bit = true;
      extraPackages = with pkgs; [
        rocmPackages.clr.icd # opencl
        libvdpau-va-gl
      ];
    };
    amdgpu = {
      overdrive.enable = true;
      opencl.enable = true;
      initrd.enable = true;
    };
  };

  # lact
  systemd.packages = with pkgs; [ lact ];
  systemd.services.lact.enable = true;

  # SSD
  services.fstrim.enable = true;

  # Firmware updates
  services.fwupd.enable = true;

  # Peripherals
    # General
  services.ratbagd.enable = true;

    # Mouse
  hardware.logitech.wireless.enable = true;
  hardware.logitech.wireless.enableGraphical = true; # solaar for logitech XDDDDDDD

    # Keyboard
  hardware.keyboard.qmk.enable = true;

    # Headset (although.. the base station is wired and that handles it, oh well I'll keep it around)
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
