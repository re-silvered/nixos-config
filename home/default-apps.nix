{ ... }:

{
  xdg.mimeApps = {
    enable = true;

    defaultApplications = {
      "text/html" = "firefox.desktop";
      "x-scheme-handler/http" = "firefox.desktop";
      "x-scheme-handler/https" = "firefox.desktop";
      "x-scheme-handler/about" = "firefox.desktop";
      "x-scheme-handler/unknown" = "firefox.desktop";

      "x-scheme-handler/mailto" = "thunderbird.desktop";

      "x-scheme-handler/discord" = "discord.desktop";

      "x-scheme-handler/steam" = "steam.desktop";
    };
  };
}