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

    dotnet-runtime
    dotnet-sdk
    dotnet-aspnetcore

    wineWow64Packages.stable
    winetricks

    # VRC creator tools
    alcom
    unityhub
    vrc-get

    # Unity version required for the above
    (pkgs.writeShellApplication {
      name = "install-vrchat-unity";
      runtimeInputs = [ unityhub ];
      text = ''
        unityhub --headless install \
          --version 2022.3.22f1 \
          --changeset b9e6e7e9fa2d \
          --module android android-sdk-ndk-tools android-open-jdk 
      '';
    })

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
