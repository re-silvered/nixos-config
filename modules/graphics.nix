{ pkgs, ... }:

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
    (kdePackages.wallpaper-engine-plugin.overrideAttrs (_old: {
      version = "0-unstable-2026-06-13";
      src = fetchFromGitHub {
        owner = "RainyPixel";
        repo = "wallpaper-engine-kde-plugin";
        rev = "c0c08ad73a1eb773acbcd7854d2807115bd9d5a6";
        fetchSubmodules = true;
        hash = "sha256-516wvxhMPxMulzEWnf4LvPIRqfVPOM9OLnFZQ1gVqGU=";
      };
      # This fork has native file handling and updated Qt support.
      patches = [ ];
      postInstall = "";
    }))
    # Make optional wallpaper backends available through Plasma's QML import path.
    kdePackages.qtmultimedia
    kdePackages.qtwebchannel
    kdePackages.qtwebengine
    kdePackages.qtwebsockets
    papirus-icon-theme
    capitaine-cursors
  ];
}
