{ lib
, symlinkJoin
, makeWrapper
, forceWayland ? false
, forceDarkMode ? false
, WebRTCPipeWireCapturer ? true
, SystemNotifications ? true
, TouchpadOverscrollHistoryNavigation ? true
, package
}:
let
  enableFeatures = lib.concatStringsSep "," ([ "UseOzonePlatform" "WaylandWindowDecorations" "WebUIDarkMode" ]
    ++ (lib.optional SystemNotifications "SystemNotifications")
    ++ (lib.optional TouchpadOverscrollHistoryNavigation "TouchpadOverscrollHistoryNavigation")
    ++ (lib.optional WebRTCPipeWireCapturer "WebRTCPipeWireCapturer")
  );
in
if lib.hasAttr "commandLineArgs" (lib.functionArgs package.override)
then
  (package.override {
    commandLineArgs = [
      "--enable-features=${enableFeatures}"
      (if forceWayland then "--ozone-platform=wayland" else "--ozone-platform-hint=auto")
    ]
    ++ lib.optional forceDarkMode "--force-dark-mode";
  })
else
  let
    mainProgram =
      if lib.hasAttr "mainProgram" package.meta
      then package.meta.mainProgram
      else package.pname;
  in
  symlinkJoin {
    name = "${mainProgram}-wayland";
    paths = [ package ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${mainProgram} \
        --add-flags "--enable-features=${enableFeatures}" \
        --add-flags "${if forceWayland then "--ozone-platform=wayland" else "--ozone-platform-hint=auto"}" \
        ${lib.optionalString forceDarkMode ''--add-flags "--force-dark-mode"''}
    '';
  }
