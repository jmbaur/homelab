{ lib
, symlinkJoin
, makeWrapper
, WebRTCPipeWireCapturer ? true
, SystemNotifications ? true
, TouchpadOverscrollHistoryNavigation ? true
, ...
}:
let
  enableFeatures = lib.concatStringsSep "," ([ "UseOzonePlatform" "WaylandWindowDecorations" "WebUIDarkMode" ]
    ++ (lib.optional SystemNotifications "SystemNotifications")
    ++ (lib.optional TouchpadOverscrollHistoryNavigation "TouchpadOverscrollHistoryNavigation")
    ++ (lib.optional WebRTCPipeWireCapturer "WebRTCPipeWireCapturer")
  );
in
drv:
if lib.hasAttr "commandLineArgs" (lib.functionArgs drv.override)
then
  (drv.override {
    commandLineArgs = [
      "--enable-features=${enableFeatures}"
      "--ozone-platform-hint=auto"
      "--force-dark-mode"
    ];
  })
else
  let
    mainProgram =
      if lib.hasAttr "mainProgram" drv.meta
      then drv.meta.mainProgram
      else drv.pname;
  in
  symlinkJoin {
    name = "${mainProgram}-wayland";
    paths = [ drv ];
    buildInputs = [ makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${mainProgram} \
      --add-flags "--enable-features=${enableFeatures}" \
      --add-flags "--ozone-platform-hint=auto" \
      --add-flags "--force-dark-mode"
    '';
  }
