{ ... }:

{
  programs.plasma = {
    enable = true;
    workspace.iconTheme = "Papirus-Dark";
    kwin.effects.blur = {
      enable = true;
      strength = 1;
      noiseStrength = 1;
    };

    shortcuts = {
      "services/kitty.desktop"."_launch" = "Ctrl+Alt+T";
      "services/org.kde.konsole.desktop"."_launch" = [ ];
    };

    configFile."kdeglobals"."General" = {
      TerminalApplication = "kitty";
      TerminalService = "kitty.desktop";
    };

    kscreenlocker = {
      autoLock = false;

      appearance = {
	      showMediaControls = true;
      };
    };
  };

  # This script automatically fixes paper icons by converting
  # Nix Store paths to generic application references.
  home.activation.clean-plasma-launchers = lib.hm.dag.entryAfter ["writeBoundary"] ''
    $DRY_RUN_CMD sed -i 's|file:///nix/store/[^/]*/share/applications/|applications:|g' \
      ${config.home.homeDirectory}/.config/plasma-org.kde.plasma.desktop-appletsrc || true
  '';
};