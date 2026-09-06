{ config, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Atom";
    shellIntegration.enableBashIntegration = true;
  };
}