{ config, pkgs, ... }:

{
  # Plasma
  services.desktopManager.plasma6.enable = true;
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Wayland tweak for the RX 9060 XT
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; 
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
    xkb = {
      layout = "au";
      variant = "";
    };
  };

  # Ricing
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    capitaine-cursors
  ];
}
