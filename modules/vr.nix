{ config, pkgs, ... }:

let
  # Keep a writable copy in Documents
  ignitionFiles = pkgs.stdenvNoCC.mkDerivation {
    pname = "psvr2-ignition-files";
    version = "1.1.0";
    src = pkgs.fetchurl {
      url = "https://github.com/BnuuySolutions/Ignition/releases/download/v1.1.0/Ignition-Linux-Windows.zip";
      sha256 = "2637bb32c3e9d4ce2f8d8af4f1eaa7f2affe4c4f544868988ba4fd7da9e0f7ec";
    };
    toolkit = pkgs.fetchurl {
      url = "https://github.com/BnuuySolutions/PSVR2Toolkit/releases/download/v1.0.0-experimental-3/PSVR2TK-win64-Ignition.zip";
      sha256 = "306e6bf9465b9266233db69e0c2175056b8cbed5dba0024e78dd056dbb0c6f67";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/ignition" "$out/toolkit"
      unzip "$src" -d "$out/ignition"
      unzip "$toolkit" -d "$out/toolkit"
      for script in "$out/ignition/"*.sh "$out/ignition/proton"; do
        substituteInPlace "$script" --replace-fail '#!/bin/bash' '#!${pkgs.bash}/bin/bash'
        chmod +x "$script"
      done
      # The upstream auto-selection can choose Hotfix instead of Experimental.
      substituteInPlace "$out/ignition/launch_serverhelper.sh" \
        --replace-fail 'unset SteamGameId' 'unset SteamGameId
      export PROTONVERSION="Proton - Experimental"'
    '';
  };
  psvr2Setup = pkgs.writeShellApplication {
    name = "psvr2-setup";
    runtimeInputs = with pkgs; [ bash coreutils jq steam-run ];
    text = ''
      # Optional arguments support Steam libraries on other disks.
      common="$HOME/.local/share/Steam/steamapps/common"
      app="''${1:-$common/PlayStation VR2 App}"
      steamvr="''${2:-$common/SteamVR}"
      driver="$app/SteamVR_Plug-In"
      for required in "$driver/driver.vrdrivermanifest" "$steamvr/bin/vrpathreg.sh"; do
        if [[ ! -f "$required" ]]; then
          echo "Missing: $required" >&2
          echo 'Install PlayStation VR2 App (2580190) and SteamVR (250820) in Steam first.' >&2
          exit 1
        fi
      done
      if [[ ! -f "$common/Proton - Experimental/proton" ]]; then
        echo 'Install Proton Experimental in the default Steam library first.' >&2
        exit 1
      fi
      win64="$driver/bin/win64"
      if [[ ! -f "$win64/driver_playstation_vr2.dll" ]]; then
        echo "Missing Sony driver in $win64; verify the app in Steam." >&2
        exit 1
      fi
      if [[ $(jq -r .name "$driver/driver.vrdrivermanifest") != playstation_vr2 ]]; then
        echo 'Unexpected driver manifest; refusing to modify it.' >&2
        exit 1
      fi
      echo 'Close SteamVR before running this installer. Headset firmware must be 0x06000102.'
      destination="$HOME/Documents/ignition-1.1.0"
      mkdir -p "$destination"
      cp -R ${ignitionFiles}/ignition/. "$destination/"
      chmod -R u+w "$destination"
      # Preserve the original driver.
      if [[ ! -f "$win64/driver_playstation_vr2_orig.dll" ]]; then
        cp -p "$win64/driver_playstation_vr2.dll" "$win64/driver_playstation_vr2_orig.dll"
      fi
      bash "$destination/install_ignition.sh" "$driver"
      install -m 0644 ${ignitionFiles}/toolkit/* "$win64/"
      (cd "$driver/bin/linux64"; steam-run bash "$steamvr/bin/vrpathreg.sh" adddriver "$driver")
      echo 'Driver registered'
    '';
  };
  kernel = config.boot.kernelPackages.kernel;
  patchedAmdgpu = pkgs.stdenv.mkDerivation {
    pname = "amdgpu-ignore-ctx-privileges";
    inherit (kernel) src version postPatch nativeBuildInputs;
    patches = (kernel.patches or []) ++ [
      (pkgs.fetchpatch {
        name = "cap_sys_nice_begone.patch";
        url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
        hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
      })
    ];

    hardeningDisable = [ "pic" "format" ];
    enableParallelBuilding = true;
    modulePath = "drivers/gpu/drm/amd/amdgpu";

    buildPhase = ''
      runHook preBuild
      kernelBuild=${kernel.dev}/lib/modules/${kernel.modDirVersion}/build
      cp "$kernelBuild/Module.symvers" .
      cp "$kernelBuild/.config" .
      cp ${kernel.dev}/vmlinux .

      make -j"$NIX_BUILD_CORES" modules_prepare
      make -j"$NIX_BUILD_CORES" M="$modulePath" modules
      runHook postBuild
    '';

    installPhase = ''
      runHook preInstall
      make INSTALL_MOD_PATH="$out" \
        XZ="xz -T$NIX_BUILD_CORES" \
        M="$modulePath" modules_install
      runHook postInstall
    '';
  };
in
{
  hardware.steam-hardware.enable = true;
  services.udev.packages = [ pkgs.xr-hardware ];

  environment.systemPackages = [
    pkgs.slimevr # :godo:
    pkgs.jq
    psvr2Setup
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  # Replaces the stock module in both the system and the early-boot initrd.
  # The kernel itself remains eligible for the normal NixOS binary cache.
  boot.extraModulePackages = [ patchedAmdgpu ];
}
