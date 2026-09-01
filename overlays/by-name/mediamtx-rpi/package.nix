{
  lib,
  buildGoModule,
  mediamtx-rpicamera,
  fetchFromGitHub,
  fetchurl,
  nixosTests,
}:

let
  hlsJs = fetchurl {
    url = "https://cdn.jsdelivr.net/npm/hls.js@v1.7.1/dist/hls.min.js";
    hash = "sha256-bPrXAaYfuKma3V6ERJ5kZhFpsGUr9EzrKihGXIgXtfE=";
  };
in
buildGoModule (finalAttrs: {
  pname = "mediamtx";
  # check for hls.js version updates in internal/servers/hls/hlsjsdownloader/VERSION
  # check for mtxrpicam version updates in internal/staticsources/rpicamera/mtxrpicamdownloader/VERSION
  version = "1.20.1";

  src = fetchFromGitHub {
    owner = "bluenviron";
    repo = "mediamtx";
    tag = "v${finalAttrs.version}";
    hash = "sha256-L9dRwOD5JCu3ZczTxeb3a6ShHMXGWNXVN5KAa/7bcjM=";
  };

  vendorHash = "sha256-15ERQ4TYJ+atLS3ZrOMtSq5UDWh0Q2xejepQlEJWPL4=";

  patches = [ ./uninsane.patch ];
  postPatch = ''
    cp ${hlsJs} internal/servers/hls/hls.min.js
    echo "v${finalAttrs.version}" > internal/core/VERSION

    install -D ${mediamtx-rpicamera}/bin/mtxrpicam internal/staticsources/rpicamera/mtxrpicam_32/mtxrpicam
    install -D ${mediamtx-rpicamera}/bin/mtxrpicam internal/staticsources/rpicamera/mtxrpicam_64/mtxrpicam
  '';

  subPackages = [ "." ];

  # Tests need docker
  doCheck = false;

  passthru.tests = {
    inherit (nixosTests) mediamtx;
  };

  meta = {
    description = "SRT, WebRTC, RTSP, RTMP, LL-HLS media server and media proxy";
    inherit (finalAttrs.src.meta) homepage;
    license = lib.licenses.mit;
    mainProgram = "mediamtx";
    maintainers = with lib.maintainers; [ fpletz ];
  };
})
