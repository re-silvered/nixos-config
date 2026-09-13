{ pkgs, ... }:

{
  # Plasma
  services.desktopManager.plasma6.enable = true;
  environment.plasma6.excludePackages = [ pkgs.kdePackages.konsole ];
  services.displayManager.sddm = {
    enable = true;
    wayland.enable = true;
  };

  # Wayland tweak
  environment.sessionVariables = {
    NIXOS_OZONE_WL = "1"; 
  };

  # Enable the X11 windowing system.
  services.xserver = {
    enable = true;
    videoDrivers = [ "amdgpu" ];
  };

  # RDP
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true; # TCP Port 3389
  };

  # Ricing
  environment.systemPackages = with pkgs; [
    papirus-icon-theme
    capitaine-cursors
  ];
}
