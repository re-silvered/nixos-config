{ pkgs, ... }:

{
  # Allow unfree packages
  nixpkgs.config.allowUnfree = true;

  services.flatpak.enable = true;

  environment.systemPackages = with pkgs; [
    git
    wget
    curl
    psmisc
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
    unrar

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

    (with dotnetCorePackages; combinePackages [
    sdk_10_0
    ])

    (pkgs.writeShellApplication {
      name = "rebuild";

      runtimeInputs = with pkgs; [
       python3
      ];

      text = builtins.readFile ../scripts/rebuild.sh;
    })
  ];

  environment.sessionVariables = {
  DOTNET_ROOT = "${pkgs.dotnetCorePackages.sdk_10_0}/share/dotnet";
  };
}
