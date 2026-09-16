{ pkgs, inputs, ... }:

{
  programs.steam = {
    enable = true;
    dedicatedServer.openFirewall = true; # Ports 27015-tcp/udp
    package = pkgs.millennium-steam.override {
      extraProfile = ''
        # Allows Monado/WiVRn to be used
        export PRESSURE_VESSEL_IMPORT_OPENXR_1_RUNTIMES=1
        # Fixes timezones on VRChat
        unset TZ
      '';
    };
  };

  nixpkgs.overlays = [ inputs.millennium.overlays.default ];

  programs.gamemode = {
    enable = true;
    settings.custom = {
      start = "${pkgs.libnotify}/bin/notify-send 'GameMode started'";
      end = "${pkgs.libnotify}/bin/notify-send 'GameMode ended'";
    };
  };

  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
}
