# Edit this configuration file to define what should be installed on
# your system. Help is available in the configuration.nix(5) man page, on
# https://search.nixos.org/options and in the NixOS manual (`nixos-help`).

{ config, pkgs, inputs, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./modules
    ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
  boot.kernelPackages = pkgs.linuxPackages_latest;

  my.ups.enable = false; # Remove when you do finally plug that bitch in

  # Localisation
  time.timeZone = "Australia/Melbourne";
  i18n.defaultLocale = "en_AU.UTF-8";

  users.users."silver" = {
    isNormalUser = true;
    description = "You!";
    extraGroups = [
      "networkmanager"
      "wheel" 
    ];
    packages = with pkgs; [
      kdePackages.kate
    ];
  };



  systemd.sleep.settings.Sleep = { # I know how to use home+L
    AllowHibernation = "no";
    AllowHybridSleep = "no";
    AllowSuspendThenHibernate = "no";
  };

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes" 
    ];
    auto-optimise-store = true;
  };

  nix.gc = {
    automatic = true;
    dates = "weekly";
    options = "--delete-older-than 30d";
  };

  system.stateVersion = "26.05"; # ! DO NOT TOUCH !

}
