{ pkgs, ... }:

{
  programs.keepassxc = {
    enable = true;
    autostart = true;
    settings = {
      FdoSecrets = {
        Enabled = true;
        ConfirmAccessItem = false;
      };

      Browser.Enabled = true;
    };
  };

  xdg.autostart.enable = true;

  xdg.configFile."kwalletrc".text = ''
    [Wallet]
    Enabled=true

    [org.freedesktop.secrets]
    apiEnabled=false

    [KSecretD]
    Enabled=false
  ''; # begone stinky
}
