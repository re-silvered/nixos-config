{ config, pkgs, ... }:
# Have fun looking through this
let
  slimevrDriver = pkgs.stdenvNoCC.mkDerivation {
    pname = "slimevr-openvr-driver";
    version = "6.0.0";
    src = pkgs.fetchurl {
      url = "https://github.com/SlimeVR/SlimeVR-OpenVR-Driver/releases/download/v6.0.0/slimevr-openvr-driver-x64-linux.zip";
      sha256 = "97e7b2210b5046a7fb4524fb4288ed8a0046dc7930ac8b4aff1143a870760dd7";
    };
    nativeBuildInputs = with pkgs; [ unzip autoPatchelfHook ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/share"
      unzip "$src" -d "$out/share"
    '';
  };
  slimevrSetup = pkgs.writeShellApplication {
    name = "slimevr-setup";
    runtimeInputs = with pkgs; [ bash steam-run ];
    text = ''
      common="''${STEAM_COMMON:-$HOME/.local/share/Steam/steamapps/common}"
      if [[ ! -f "$common/SteamVR/bin/vrpathreg.sh" ]]; then
        echo '[ERR] SteamVR is missing; set STEAM_COMMON to its steamapps/common directory.' >&2
        exit 1
      fi
      cd "$HOME"
      steam-run bash "$common/SteamVR/bin/vrpathreg.sh" adddriver ${slimevrDriver}/share/slimevr
      echo '[ERR] SlimeVR driver registered'
    '';
  };
  baballoniaRuntime = (pkgs.steam.override {
    extraLibraries = p: with p; [ libice libsm ];
  }).run;
  baballoniaVr = pkgs.writeShellApplication {
    name = "baballonia-vr";
    runtimeInputs = with pkgs; [ coreutils procps ];
    text = ''
      common="''${STEAM_COMMON:-$HOME/.local/share/Steam/steamapps/common}"
      app="''${BABALLONIA_DIR:-$common/Baballonia}"
      if [[ ! -x "$app/Baballonia.Desktop" ]]; then
        echo '[ERR] Baballonia.desktop is missing; set BABALLONIA_DIR to the installed app directory.' >&2
        exit 1
      fi
      server=$(pgrep -n -u "$UID" -x vrserver || true)
      if [[ -z "$server" ]]; then
        echo '[ERR] Start SteamVR with vr-start before attempting cameras' >&2
        exit 1
      fi
      locator="/proc/$server/root/tmp/psvr2tk_capi_path.txt"
      for ((attempt = 0; attempt < 80; attempt++)); do
        [[ -r "$locator" ]] && break
        sleep 0.25
      done
      if [[ ! -r "$locator" ]]; then
        echo '[ERR] SteamVR has not published the Toolkit C API path. Check that the PSVR2 Toolkit driver loaded.' >&2
        exit 1
      fi
      # Only the locator lives in private /tmp while the camera IPC uses /dev/shm so we copy the live driver's locator into a directory visible in both runtimes.
      export TMPDIR="''${XDG_RUNTIME_DIR:?Desktop runtime directory is missing}/psvr2-toolkit"
      mkdir -p "$TMPDIR"
      chmod 0700 "$TMPDIR"
      cp "$locator" "$TMPDIR/psvr2tk_capi_path.txt"
      cd "$app"
      # Steam Linux Runtime 4 lacks the GStreamer libraries used by OpenCvSharp :()
      export SteamAppId=4091970
      export SteamGameId=4091970
      exec ${baballoniaRuntime}/bin/steam-run ./Baballonia.Desktop "$@"
    '';
  };
  steamvrLinuxFixes = pkgs.stdenvNoCC.mkDerivation {
    pname = "steamvr-linux-fixes";
    version = "0.2.1";
    src = pkgs.fetchurl {
      url = "https://github.com/BnuuySolutions/SteamVRLinuxFixes/releases/download/v0.2.1/VK_LAYER_BNUUY_steamvr_linux_fixes.zip";
      sha256 = "af649a5aa45b732aa29989c401d23d9088f013c105c1d94893d77192addb6d05";
    };
    nativeBuildInputs = with pkgs; [ unzip autoPatchelfHook ];
    buildInputs = with pkgs; [ stdenv.cc.cc.lib vulkan-loader ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/lib" "$out/share/vulkan/implicit_layer.d"
      unzip "$src" -d unpacked
      install -m 0755 unpacked/libsteamvr_linux_fixes.so "$out/lib/"
      install -m 0644 unpacked/VkLayer_steamvr_linux_fixes.json "$out/share/vulkan/implicit_layer.d/"
      substituteInPlace "$out/share/vulkan/implicit_layer.d/VkLayer_steamvr_linux_fixes.json" \
        --replace-fail '../../../lib/libsteamvr_linux_fixes.so' "$out/lib/libsteamvr_linux_fixes.so"
    '';
  };
  psvr2Extras = pkgs.stdenvNoCC.mkDerivation {
    pname = "psvr2-extras";
    version = "1.0.2";
    src = pkgs.fetchurl {
      url = "https://github.com/BnuuySolutions/vr2jb/releases/download/v1.0.2/vr2jb-windows-linux-builds-v1.0.2.zip";
      sha256 = "a9b50b60ea308fc63e0abb6309b8d092c8cb44d2f83d0cb2b742b22296b80965";
    };
    baballoniaModule = pkgs.fetchurl {
      url = "https://github.com/BnuuySolutions/PSVR2Toolkit.Baballonia/releases/download/v0.1.0/PSVR2Toolkit.Baballonia-Ignition.zip";
      sha256 = "f3adc4af6c469a6457d65b6568964005345d9b6a88bd6df24465811d4ac1c368";
    };
    nativeBuildInputs = [ pkgs.unzip ];
    dontUnpack = true;
    installPhase = ''
      mkdir -p "$out/jailbreak" "$out/module"
      unzip "$src" -d "$out/jailbreak"
      rm "$out/jailbreak/vr2jb.exe"
      chmod +x "$out/jailbreak/"*
      unzip "$baballoniaModule" -d "$out/module"
    '';
  };

  wayvr = pkgs.symlinkJoin {
    name = "wayvr-with-steamvr-libraries";
    paths = [ pkgs.wayvr ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram "$out/bin/wayvr" --prefix LD_LIBRARY_PATH : \
        ${pkgs.lib.makeLibraryPath (with pkgs; [ libglvnd libuuid vulkan-loader wayland pipewire libxkbcommon libinput ])}
    '';
  };

  vrStart = pkgs.writeShellApplication {
    name = "vr-start";
    runtimeInputs = with pkgs; [ coreutils gawk gnugrep gnused libcap procps steam-run systemd util-linux ];
    text = ''
      if [[ "$EUID" == 0 ]]; then
        echo '[ERR] Run vr-start in userspace !' >&2
        exit 1
      fi
      mode="''${1:-start}"
      case "$mode" in
        start|--baballonia) ;;
        --help|-h)
          echo 'Usage: vr-start [--baballonia]'
          echo 'Default: reuse running SteamVR, or jailbreak and start a new session.'
          echo 'Start WayVR and Baballonia if they are not already running.'
          echo '--baballonia: restart only Baballonia (used for debugging atm)'
          exit 0
          ;;
        *) echo 'Usage: vr-start [--baballonia]' >&2; exit 1 ;;
      esac
      if (( $# > 1 )); then
        echo 'Usage: vr-start [--baballonia]' >&2
        exit 1
      fi
      exec 9>"''${XDG_RUNTIME_DIR:-/tmp}/psvr2-start-$UID.lock"
      flock -n 9 || { echo 'Another vr-start is running.' >&2; exit 1; }
      common="''${STEAM_COMMON:-$HOME/.local/share/Steam/steamapps/common}"
      launcher="$common/SteamVR/bin/linux64/vrcompositor-launcher.sh"
      # shellcheck disable=SC2016
      compat_default=': "''${STEAM_COMPAT_LIBRARY_PATHS:=}"'
      # shellcheck disable=SC2016
      if [[ -f "$launcher" ]] &&
        grep -Fq 'for i in ''${STEAM_COMPAT_LIBRARY_PATHS//:/}' "$launcher" &&
        ! grep -Fq "$compat_default" "$launcher"; then
        if [[ ! -e "$launcher.before-compat-library-paths-fix" ]]; then
          cp -p "$launcher" "$launcher.before-compat-library-paths-fix"
        fi
        # shellcheck disable=SC2016
        sed -i '/^set -u$/a : "''${STEAM_COMPAT_LIBRARY_PATHS:=}"' "$launcher"
        echo '! Fixed SteamVR launcher handling of unset library paths !'
      fi
      baballonia="''${BABALLONIA_DIR:-$common/Baballonia}"
      manifest="$common/../appmanifest_4091970.acf"
      if [[ -z "''${BABALLONIA_DIR:-}" && -f "$manifest" ]]; then
        installdir=$(awk -F '"' '/"installdir"/ {print $4; exit}' "$manifest")
        [[ -z "$installdir" ]] || baballonia="$common/$installdir"
      fi
      if [[ ! -x "$baballonia/Baballonia.Desktop" ]]; then
        echo '[ERR] Install Project Babble: Baballonia (4091970), or set BABALLONIA_DIR.' >&2
        exit 1
      fi
      launch_baballonia() {
        if systemctl --user is-active --quiet baballonia-vr.service; then
          echo '[INF] Baballonia is already running.'
          return
        fi
        for process in /proc/[0-9]*; do
          if [[ -O "$process" && $(readlink "$process/exe" 2>/dev/null || true) == "$baballonia/Baballonia.Desktop" ]]; then
            echo '[ERR] Baballonia is already running outside its service. Use vr-start --baballonia to restart it with the fixed runtime.'
            return
          fi
        done
        mkdir -p "$baballonia/Modules"
        install -m 0644 ${psvr2Extras}/module/* "$baballonia/Modules/"
        systemd-run --user --collect --unit=baballonia-vr \
          --setenv="BABALLONIA_DIR=$baballonia" \
          ${baballoniaVr}/bin/baballonia-vr 9>&-
      }
      launch_wayvr() {
        if systemctl --user is-active --quiet wayvr-vr.service || pgrep -u "$UID" -x wayvr >/dev/null; then
          echo '[INF] WayVR is already running.'
          return
        fi
        # Run outside Steam's container, with this desktop session's portal and
        # display environment. Force OpenVR so it attaches to SteamVR.
        local variable
        local -a session_env=()
        for variable in DISPLAY WAYLAND_DISPLAY XAUTHORITY XDG_CURRENT_DESKTOP XDG_SESSION_TYPE DBUS_SESSION_BUS_ADDRESS; do
          if [[ -v "$variable" ]]; then
            session_env+=("--setenv=$variable=''${!variable}")
          fi
        done
        systemd-run --user --collect --unit=wayvr-vr --property=Type=exec \
          "''${session_env[@]}" ${wayvr}/bin/wayvr --openvr --wait 9>&-
      }
      if [[ "$mode" == --baballonia ]]; then
        systemctl --user stop baballonia-vr.service 2>/dev/null || true
        # Close instances started through Steam because thats bad.
        for process in /proc/[0-9]*; do
          if [[ -O "$process" && $(readlink "$process/exe" 2>/dev/null || true) == "$baballonia/Baballonia.Desktop" ]]; then
            pid="''${process##*/}"
            kill -TERM "$pid"
            for ((attempt = 0; attempt < 100; attempt++)); do
              [[ -e "$process/exe" ]] || break
              sleep 0.1
            done
            if [[ -e "$process/exe" ]]; then
              echo '[ERR] Baballonia could not close? Please manually kill it.' >&2
              exit 1
            fi
          fi
        done
        launch_baballonia
        exit 0
      fi
      if pgrep -u "$UID" -x vrserver >/dev/null; then
        echo '[INF] Reusing SteamVR. Jailbreak and driver setup were not rerun.'
        launch_wayvr
        launch_baballonia
        exit 0
      fi
      compositor="$common/SteamVR/bin/linux64/vrcompositor-launcher"
      if [[ ! -f "$compositor" ]]; then
        echo "[ERR] SteamVR compositor launcher is missing: $compositor" >&2
        exit 1
      fi
      if [[ $(getcap "$compositor") != *cap_sys_nice* ]]; then
        echo '[ERR] SteamVR needs a one-time compositor capability setup after updates' >&2
        printf 'sudo %q CAP_SYS_NICE=eip %q\n' '${pkgs.libcap}/bin/setcap' "$compositor" >&2
        echo 'Rerun vr-start' >&2
        exit 1
      fi
      driver="$common/PlayStation VR2 App/SteamVR_Plug-In/bin/linux64"
      if [[ ! -f "$driver/ignition.json" || ! -f "$driver/driver_playstation_vr2.so" ]]; then
        echo '[INF] Run psvr2-setup first to install the Ignition driver.' >&2
        exit 1
      fi
      # Steam updates restore the headset DLL we don't want over top of the toolkit one.
      if ! cmp -s ${ignitionFiles}/toolkit/driver_playstation_vr2.dll \
        "$common/PlayStation VR2 App/SteamVR_Plug-In/bin/win64/driver_playstation_vr2.dll"; then
        echo '[INF] Steam replaced the Toolkit driver, restoring the pinned installation...'
        ${psvr2Setup}/bin/psvr2-setup "$common/PlayStation VR2 App" "$common/SteamVR" 9>&-
      fi
      if ! command -v steam >/dev/null; then
        echo '[ERR] Steam is not on PATH; apply the NixOS configuration first.' >&2
        exit 1
      fi
      # Store fuckery
      layers="''${XDG_DATA_HOME:-$HOME/.local/share}/vulkan/implicit_layer.d"
      mkdir -p "$layers"
      install -m 0644 ${steamvrLinuxFixes}/share/vulkan/implicit_layer.d/*.json "$layers/"
      cd "$HOME"
      ${slimevrSetup}/bin/slimevr-setup 9>&-
      echo '[INF] Applying the PSVR2 jailbreak (requires firmware 0x06000102 and USB access).'
      steam-run ${psvr2Extras}/jailbreak/vr2jb 9>&-
      echo '[INF] Success is indicated by a flashing white LED. Otherwise check patch output for error(s)'
      steam -applaunch 250820 9>&-
      ready=false
      for ((attempt = 0; attempt < 60; attempt++)); do
        if pgrep -x vrserver >/dev/null; then
          ready=true
          break
        fi
        sleep 1
      done
      if [[ "$ready" != true ]]; then
        echo '[ERR] SteamVR did not start within 60 seconds.' >&2
        exit 1
      fi
      # vrserver existing does not prove headset tracking is ready; Baballonia
      # connects through the running Toolkit driver when it becomes available.
      # Keep Baballonia in a separate user unit with journal logs and no startup
      # lock inherited. Use NixOS's FHS runtime rather than Steam Runtime 4.
      launch_wayvr
      launch_baballonia
      echo 'Launching apps...'
    '';
  };

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
          echo "[ERR] Missing: $required" >&2
          echo '[INF] Install the PlayStation VR2 App (2580190) and SteamVR (250820) on Steam first.' >&2
          exit 1
        fi
      done
      if [[ ! -f "$common/Proton - Experimental/proton" ]]; then
        echo '[ERR] Install Proton Experimental on Steam first.' >&2
        exit 1
      fi
      win64="$driver/bin/win64"
      if [[ ! -f "$win64/driver_playstation_vr2.dll" ]]; then
        echo "[ERR] Missing PSVR2 driver in $win64, verify your install" >&2
        exit 1
      fi
      if [[ $(jq -r .name "$driver/driver.vrdrivermanifest") != playstation_vr2 ]]; then
        echo '[ERR] Unexpected driver manifest? Refusing to modify it.' >&2
        exit 1
      fi
      echo '[INF] Close SteamVR before running this installer. Headset firmware !MUST! be 0x06000102.'
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
      echo '[INF] Driver registered'
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
  services.udev.packages = [ pkgs.xr-hardware pkgs.slimevr ];

  # SlimeVR trackers
  networking.firewall.interfaces.enp7s0 = {
    allowedUDPPorts = [ 6969 35903 8266 ];
    allowedTCPPorts = [ 21110 ];
  };

  environment.systemPackages = [
    pkgs.slimevr # :godo:
    pkgs.jq
    wayvr # Thank you steamvr for not being able to capture wayland natively.
    psvr2Setup
    vrStart
    baballoniaVr
    slimevrSetup
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  # As required
  boot.extraModulePackages = [ patchedAmdgpu ];
}
