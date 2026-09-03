{ config, pkgs, ... }:

{
  # Plasma
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Wayland tweak
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; 
    AMD_VULKAN_ICD = "RADV";
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };

  # Ricing
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    capitaine-cursors
  ];
}
