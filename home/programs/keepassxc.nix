{ pkgs, ... }:

{
  home.packages = [ pkgs.keepassxc ];

  home.file.".config/keepassxc/keepassxc.ini" = {
    force = true;
    text = ''
      [General]
      ConfigVersion=2

      [Browser]
      Enabled=true

      [FdoSecrets]
      Enabled=true
    '';
  };

  programs.keepassxc = {
    enable = true;
    autostart = true;
  };

  xdg.autostart.enable = true;

  xdg.configFile."kwalletrc".text = ''
    [KSecretD]
    Enabled=false
  ''; # begone stinky
}
