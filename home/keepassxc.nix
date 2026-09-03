{ pkgs, ... }:

{
  programs.keepassxc = {
    enable = true;
    autostart = true;

    settings = {
      FdoSecrets = {
        Enabled = true;
      };
    };
  };

  xdg.autostart.enable = true;

  xdg.configFile."kwalletrc".text = ''
    [KSecretD]
    Enabled=false
  ''; # begone stinky
}
