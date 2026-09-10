{ ... }:

{
  services.linux-wallpaperengine = {
    enable = true;
    assetsPath = "/home/silver/.local/share/Steam/steamapps/common/wallpaper_engine/assets/";
    wallpapers = [
      {
        monitor = "main";
        wallpaperId = "3302436589";
        audio.silent = true;
        scaling = "stretch";
      }
    ];
  };
}