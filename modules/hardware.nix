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

  ## Peripherals
  # General
  services.ratbagd.enable = true;

  # Keyboard
  hardware.keyboard.qmk.enable = true;

  services.xserver.xkb = {
    layout = "au";
    variant = "";
  };

  # Headset / Speakers
  services.arctis-sound-manager.enable = true;

  services.pulseaudio.enable = false; # I mean if I'm handling graphics in here too...
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Anything else
  hardware.bluetooth = {
    enable = true;
    powerOnBoot = false;
  };
}
