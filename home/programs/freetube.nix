{ ... }:

{
  programs.freetube = {
    enable = false;
    settings = {
      checkForUpdates = false;
    };
  };
}