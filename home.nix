{ config, pkgs, inputs, ... }:

{
  imports = [ 
    inputs.nixcord.homeModules.nixcord 
    ./home/programs/nixcord.nix
    ./home/programs/keepassxc.nix
    ./home/programs/firefox.nix
];

  home.username = "silver";
  home.homeDirectory = "/home/silver";
  home.stateVersion = "26.05";

  programs.home-manager.enable = true;

  home.packages = with pkgs; [
    libreoffice-fresh
    thunderbird
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
}
