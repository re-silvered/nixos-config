{ pkgs, ... }:

{

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl

    vim # TODO: learn this

    htop
    btop
    tree
    ripgrep
    jq
    unzip
    p7zip
    fastfetch

    pciutils
    usbutils
    lm_sensors
    smartmontools
    nvme-cli


    wl-clipboard
    xclip

    mangohud

    (writeShellScriptBin "rebuild"
      (builtins.readFile ../scripts/rebuild.sh))
  ];
}
