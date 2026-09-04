{ pkgs, ... }:

{

  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    eza
    ripgrep

    vim # TODO: learn this

    htop
    btop
    tree
    jq
    unzip
    p7zip
    fastfetch
    ffmpeg

    pciutils
    usbutils
    lm_sensors
    smartmontools
    nvme-cli

    wl-clipboard
    xclip

    (writeShellScriptBin "rebuild"
      (builtins.readFile ../scripts/rebuild.sh))
  ];
}
