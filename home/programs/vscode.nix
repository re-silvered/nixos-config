{ pkgs, ... }:
 # TODO: Refactor to "https://github.com/nix-community/nix-vscode-extensions" format when you can be bothered and no longer tired
{
  programs.vscode = {
    enable = true;
    extensions = with pkgs.vscode-extensions; [
      vscodevim.vim # mashallah I will learn

      jnoortheen.nix-ide

      ms-vscode.cpptools
      # ms-vscode.cpp-devtools # not in nixpkgs?
      ms-vscode.cpptools-extension-pack
      # ms-vscode.cpptools-themes # *cries*
      ms-vscode.cmake-tools

      ms-dotnettools.csdevkit
      ms-dotnettools.vscode-dotnet-runtime
      csharpier.csharpier-vscode

      eamodio.gitlens
      editorconfig.editorconfig
      esbenp.prettier-vscode
      yzhang.markdown-all-in-one

      /* Theming */
      dracula-theme.theme-dracula
      aaron-bond.better-comments
      naumovs.color-highlight
    ];
    userSettings = {
      "editor.fontSize" = 14;
      "workbench.colorTheme" = "Dracula";
      "gitlens.plusFeatures.enabled" = false;
    };
  };
}
