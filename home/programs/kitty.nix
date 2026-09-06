{ ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Atom";
    font.name = "JetBrainsMono Nerd Font";
    font.size = 10;
    shellIntegration.enableBashIntegration = true;
  };
}