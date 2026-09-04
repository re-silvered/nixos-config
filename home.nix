{ config, pkgs, inputs, ... }:

{
  imports = [ 
    inputs.nixcord.homeModules.nixcord 
    ./home/nixcord.nix
    ./home/keepassxc.nix
];


  home.username = "silver";
  home.homeDirectory = "/home/silver";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    libreoffice-fresh
    thunderbird
    librewolf
    vscode
    telegram-desktop

    krita
    kdePackages.kdenlive
    obs-studio

    mangohud
    protonup-qt

    kdePackages.kleopatra
    gnupg
    pinentry-qt
    tor-browser
  ];

  services.flatpak = {
    enable = true;
    packages = [
      "com.spotify.Client" # put it here for troubleshooting but keeping it, meh
    ];

    update.auto = {
      enable = true;
      onCalendar = "weekly";
    };

    uninstallUnmanaged = false;
  };

  home.sessionVariables = {
    BROWSER = "librewolf";
  };

  programs.bash = {
  enable = true;

    shellAliases = {
      update-nix = "cd /etc/nixos && sudo nix flake update";
      ll = "ls -lah";
    };
  };

  programs.plasma = {
    enable = true;
    kscreenlocker = {
      autoLock = false;

      appearance = {
	showMediaControls = true;
      };
    };
  };

  programs.nixcord = {
    enable = true;

    discord.enable = false;
    equibop.enable = true;

    quickCss = 
      '' button[aria-label="Send a gift"], 
	 div[aria-label="Send a gift"] { 
         display: none !important;}
      ''; # fuck outta here with that
  };
}
