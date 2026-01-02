{
  fetchFromGitHub,
  fetchgit,
  fetchurl,
  freetype,
  lib,
  libcamera,
  libjpeg,
  meson,
  ninja,
  openh264,
  pkg-config,
  stdenv,
  tinyxxd,
}:

let
  font = fetchurl {
    url = "https://github.com/IBM/plex/raw/v6.4.2/IBM-Plex-Mono/fonts/complete/ttf/IBMPlexMono-Medium.ttf";
    hash = "sha256-C+3j3r3qhIi7uSf48GUNkVBzIJc0pn/ozVozILVyURw=";
  };
in

stdenv.mkDerivation (finalAttrs: {
  pname = "mediamtx-rpicamera";
  version = "2.5.1";

  src = fetchFromGitHub {
    owner = "bluenviron";
    repo = "mediamtx-rpicamera";
    tag = "v${finalAttrs.version}";
    hash = "sha256-G8tnvo2Elc6a+7cHo7SKfEwF2sUzD9C92Pj4qdlOxIo=";
  };

  patches = [ ./uninsane.patch ];

  # look at text_font.sh
  postPatch = ''
    cat <${font} >text_font.ttf
    xxd --include text_font.ttf >text_font.h
  '';

  nativeBuildInputs = [
    meson
    tinyxxd
    ninja
    pkg-config
  ];

  buildInputs = [
    # TODO(jared): mediamtx-rpicamera does not yet support libcamera 0.6.0
    (libcamera.overrideAttrs (
      final: prev: {
        version = "0.5.2";
        src = fetchgit {
          url = "https://git.libcamera.org/libcamera/libcamera.git";
          rev = "v${final.version}";
          hash = "sha256-nr1LmnedZMGBWLf2i5uw4E/OMeXObEKgjuO+PUx/GDY=";
        };
        mesonFlags = lib.filter (flag: builtins.match ".*libunwind.*" flag == null) prev.mesonFlags;
      }
    ))
    freetype
    libjpeg
    openh264
  ];
})
