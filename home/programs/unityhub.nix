{ config, lib, pkgs, ... }:
# So Alcom can work with bubblewrapped unity.
let
  unityhub = pkgs.unityhub;

  fhsBin = "${unityhub.fhsEnv}/bin/unityhub-fhs-env";

  unityVersion = "2022.3.22f1";
  editorDir = "${config.home.homeDirectory}/Unity/Hub/Editor/${unityVersion}/Editor";

  wrapper = pkgs.writeShellScript "unity-fhs" ''
    real="${editorDir}/Unity.real"
    exec -a "$real" "${fhsBin}" "$real" "$@"
  '';
in
{
  home.packages = [ unityhub ];

  home.activation.wrapUnityFhs = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    editor="${editorDir}"
    if [ -x "$editor/Unity" ] && [ ! -e "$editor/Unity.real" ]; then
      $DRY_RUN_CMD mv "$editor/Unity" "$editor/Unity.real"
      $DRY_RUN_CMD install -m755 ${wrapper} "$editor/Unity"
    fi
  '';
}
