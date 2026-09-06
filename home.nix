{ config, pkgs, inputs, ... }:

{
  imports = [ 
    inputs.nixcord.homeModules.nixcord 
    ./home/programs
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
    kdePackages.kdenlive
    obs-studio

    mangohud
    protonup-qt

    kdePackages.kleopatra
    gnupg
    pinentry-qt
    tor-browser
  ];

  programs.bash = {
  enable = true;

    shellAliases = {
      update-nix = "cd /etc/nixos && sudo nix flake update";
      ll = "eza -lah";
    };
  };

  programs.plasma = {
    enable = true;
    workspace.iconTheme = "Papirus-Dark";
    kscreenlocker = {
      autoLock = false;

      appearance = {
	      showMediaControls = true;
      };
    };
  };
}
