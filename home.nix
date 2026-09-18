{ config, pkgs, inputs, ... }:

{
  imports = [ 
    inputs.nixcord.homeModules.nixcord 
    ./home/programs
    ./home/default-apps.nix
];

  home.username = "silver";
  home.homeDirectory = "/home/silver";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    libreoffice-fresh
    thunderbird
    telegram-desktop
    spotify

    krita
    gimp
    kdePackages.kdenlive
    obs-studio

    mangohud
    protonup-qt

    remmina # Windows RDP
    moonlight-qt # Game streaming (one day they'll all support linux...)

    kdePackages.kleopatra
    gnupg
    pinentry-qt
    tor-browser
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      update-nix = "cd /etc/nixos && sudo nix flake update";
      ll = "eza -lah";
    };

    bashrcExtra = "[[ $- != *i* ]] && return \n fastfetch";
  };

  programs.plasma = {
    enable = true;
    workspace.iconTheme = "Papirus-Dark";
    kwin.effects.blur = {
      enable = true;
      strength = 1;
      noiseStrength = 1;
    };

    shortcuts = {
      "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
      "services/org.kde.konsole.desktop"."_launch" = [ ];
    };

    configFile."kdeglobals"."General" = {
      TerminalApplication = "kitty";
      TerminalService = "kitty.desktop";
    };

    kscreenlocker = {
      autoLock = false;

      appearance = {
	      showMediaControls = true;
      };
    };
  };
}
