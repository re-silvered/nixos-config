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
      linux_display_server = "wayland";
      background_opacity = "0.7";
      background_blur = "1";
      tab_bar_style = "fade";
      cursor_trail = "1";
    };
  };
}
