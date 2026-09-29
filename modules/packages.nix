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
    direnv

    htop
    btop
    rocmPackages.rocm-smi
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
    dmidecode
    read-edid

    wl-clipboard
    xclip
    cifs-utils

    wineWow64Packages.stagingFull
    winetricks

    haruna

    # VRCFury
    (pkgs.writeShellApplication {
      name = "add-vrcfury-repository";
      runtimeInputs = [ vrc-get ];
      text = ''
        vrc-get repo add https://vcc.vrcfury.com
      '';
    })

    (pkgs.writeShellApplication {
      name = "rebuild";

      runtimeInputs = with pkgs; [
       python3
      ];

      text = builtins.readFile ../scripts/rebuild.sh;
    })
  ];
}
