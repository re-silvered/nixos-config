{ config, pkgs, ... }:

let
  kernel = config.boot.kernelPackages.kernel;
  # Build just AMDGPU against the selected stock kernel's sources and ABI.
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

  environment.systemPackages = [
    pkgs.slimevr # :godo:
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  # Replaces the stock module in both the system and the early-boot initrd.
  # The kernel itself remains eligible for the normal NixOS binary cache.
  boot.extraModulePackages = [ patchedAmdgpu ];
}
