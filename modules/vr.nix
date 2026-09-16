{ pkgs, ... }:

{
  hardware.steam-hardware.enable = true;

  environment.systemPackages = [
    pkgs.slimevr # :godo:
  ];

  nixpkgs.config.permittedInsecurePackages = [
    "pnpm-9.15.9"
  ];

  # yayy full kernel rebuild..
  boot.kernelPatches = [
    {
      name = "amdgpu-ignore-ctx-privileges";
      patch = pkgs.fetchpatch {
        name = "cap_sys_nice_begone.patch";
        url = "https://github.com/Frogging-Family/community-patches/raw/master/linux61-tkg/cap_sys_nice_begone.mypatch";
        hash = "sha256-Y3a0+x2xvHsfLax/uwycdJf3xLxvVfkfDVqjkxNaYEo=";
      };
    }
  ];
}
