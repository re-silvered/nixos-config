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
    freetube

    krita
    gimp
    kdePackages.kdenlive
    obs-studio
    alcom
    vrc-get

    mangohud
    protonup-qt

    remmina # Windows RDP
    moonlight-qt # Game streaming (one day they'll all support linux...)

    kdePackages.kleopatra
    gnupg
    pinentry-qt
    tor-browser

    prismlauncher
  ];

  programs.bash = {
    enable = true;
    enableCompletion = true;
    shellAliases = {
      update-nix = "cd /etc/nixos && sudo nix flake update";
      ll = "eza -lah";
    };

    bashrcExtra = ''
      [[ $- != *i* ]] && return
      fastfetch
      eval "$(direnv hook bash)"
    '';
  };
}
