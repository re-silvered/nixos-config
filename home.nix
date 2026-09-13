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
    kwin.effects.blur.enable = true;

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

  xdg.configFile."kate/externaltools/Run%20Shell%20Script.ini".text = ''
    [General]
    actionName=externaltool_RunShellScript
    arguments=-e sh -c "cd %{Document:Path} && pwd && chmod -vc a+x %{Document:FileName} && ./%{Document:FileName} ; echo Press enter to continue. && read null"
    category=Tools
    cmdname=run-script
    executable=kitty
    icon=system-run
    name=Run Shell Script
    output=Ignore
    reload=false
    save=CurrentDocument
    trigger=None
    workingDir=%{Document:Path}
  '';
}
