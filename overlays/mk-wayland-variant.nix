{
  lib,
  symlinkJoin,
  makeBinaryWrapper,
  forceDarkMode ? false,
  WebRTCPipeWireCapturer ? true,
  SystemNotifications ? true,
  TouchpadOverscrollHistoryNavigation ? true,
  package,
}:

let
  enableFeatures = lib.concatStringsSep "," (
    [
      "UseOzonePlatform"
      "WaylandWindowDecorations"
    ]
    ++ (lib.optional SystemNotifications "SystemNotifications")
    ++ (lib.optional TouchpadOverscrollHistoryNavigation "TouchpadOverscrollHistoryNavigation")
    ++ (lib.optional WebRTCPipeWireCapturer "WebRTCPipeWireCapturer")
  );
in
if lib.hasAttr "commandLineArgs" (lib.functionArgs package.override) then
  (package.override {
    commandLineArgs = [
      "--enable-features=${enableFeatures}"
      "--ozone-platform=wayland"
    ] ++ lib.optional forceDarkMode "--force-dark-mode";
  })
else
  let
    mainProgram =
      if lib.hasAttr "mainProgram" package.meta then package.meta.mainProgram else package.pname;
  in
  symlinkJoin {
    name = "${mainProgram}-wayland";
    paths = [ package ];
    buildInputs = [ makeBinaryWrapper ];
    postBuild = ''
      wrapProgram $out/bin/${mainProgram} \
        --add-flags "--enable-features=${enableFeatures}" \
        --add-flags "--ozone-platform=wayland" \
        ${lib.optionalString forceDarkMode ''--add-flags "--force-dark-mode"''}
    '';
  }
