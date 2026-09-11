{ pkgs, ... }:

{
  programs.kitty = {
    enable = true;
    themeFile = "Atom";
    font.name = "JetBrainsMono Nerd Font";
    font.package = pkgs.nerd-fonts.jetbrains-mono;
    font.size = 10;
    shellIntegration.enableBashIntegration = true;
    settings = {
      background_opacity = "0.7";
    };
  };
}
