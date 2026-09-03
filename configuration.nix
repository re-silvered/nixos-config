# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules/hardware.nix
      ./modules/graphics.nix
    ];

  nix.settings.experimental-features = [ "nix-command" "flakes" ];
  system.stateVersion = "26.05"; # ! DO NOT TOUCH !

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  # Yayy interwebs
  networking = {
    hostName = "nixos";
    firewall = {
      enable = true;
    };
    networkmanager = {
      enable = true;
      plugins = with pkgs; [
	networkmanager-openvpn
	networkmanager-openconnect
      ];
    };
  };

  # Localisation
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  systemd.sleep.settings.Sleep = {
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };

  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users."silver" = {
    isNormalUser = true;
    description = "You!";
    extraGroups = [ "networkmanager" "wheel" ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    nano
    vim # TODO: learn this     
    htop
    btop
    tree
    ripgrep
    jq
    unzip
    p7zip

    pciutils
    usbutils
    lm_sensors
    smartmontools
    nvme-cli

    ripgrep
    fastfetch

    wl-clipboard # for cross-rdp clipboard
    xclip

    mangohud

    (writeShellScriptBin "rebuild" (builtins.readFile ./scripts/rebuild.sh))
  ];

  # Vidya - Start
  programs.steam = {
    enable = true;
    package = pkgs.millennium-steam;
  };

  nixpkgs.overlays = [
    inputs.millennium.overlays.default
  ];  

  programs.gamemode.enable = true;
  programs.gamescope = {
    enable = true;
    capSysNice = true;
  };
  # Vidya - End

  services.flatpak.enable = true;

  # Keep until you get off of that windows machine entirely, not needed afterwards and better to remove for security.
  services.xrdp = {
    enable = true;
    defaultWindowManager = "startplasma-x11";
    openFirewall = true; # TCP Port 3389
  };

  nix.settings.auto-optimise-store = true;

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

}
