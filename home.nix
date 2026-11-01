{ config, pkgs, inputs, ... }:

let
  # FreeRDP 3.32.0 is broken
  freerdpForRemmina =
    if pkgs.lib.versionOlder pkgs.freerdp.version "3.32.1" then
      pkgs.freerdp.overrideAttrs (_: {
        version = "3.32.1";
        src = pkgs.fetchFromGitHub {
          owner = "FreeRDP";
          repo = "FreeRDP";
          tag = "3.32.1";
          hash = "sha256-7Bk0Gh09/friNKqs9D7sNfVIZuYjXSs9fbnPD5MiLiE=";
        };
      })
    else
      pkgs.freerdp;
in
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

    (remmina.override { freerdp = freerdpForRemmina; }) # Windows RDP
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
