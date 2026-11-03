My personal NixOS config optimised for an AMD x86-intel desktop

Credits also to some people from the NixOS discord who shared their configs whose names I didn't note down :(

<!-- TREE-START -->

```text
.
├── home
│   ├── programs
│   │   ├── default.nix
│   │   ├── firefox.nix
│   │   ├── freetube.nix
│   │   ├── keepassxc.nix
│   │   ├── kitty.nix
│   │   ├── nixcord.nix
│   │   ├── plasma.nix
│   │   ├── starship.nix
│   │   ├── unityhub.nix
│   │   └── vscode.nix
│   └── default-apps.nix
├── modules
│   ├── default.nix
│   ├── gaming.nix
│   ├── graphics.nix
│   ├── hardware.nix
│   ├── networking.nix
│   ├── packages.nix
│   ├── ups.nix
│   ├── vpn-containment.nix
│   └── vr.nix
├── nixpkgs
├── configuration.nix
├── flake.nix
├── hardware-configuration.nix
└── home.nix
```

<!-- TREE-END -->

### VPN containment

`modules/vpn-containment.nix` contains all VPN confinement settings. Add desktop
applications under `services.vpnContainment.programs`:

- `mode = "always"`: replace the normal command and KDE desktop entry with a VPN launcher.
- `mode = "separate"`: retain the normal app and add a `<program>-vpn` command and KDE launcher.

qBittorrent's settings are separate because it uses a bridge internally because its ports must be reachable from outside its namespace.

Use a distinct WireGuard configuration for each simultaneous tunnel, or don't idc:

Inspect tunnels with `sudo ip netns exec <app>-vpn wg show`.

### VR

Configured for PS2VR with Ignition and PS2VRToolKit
(inc. eyetracking & FBT)

The command **`vr-start`** is included, it:
checks the driver, runs vr2jb, starts SteamVR, WayVR and Baballonia.
If SteamVR is already running, it reuses that session and starts either app if they are not already running in which case it does not repeat the jailbreak or driver setup.
