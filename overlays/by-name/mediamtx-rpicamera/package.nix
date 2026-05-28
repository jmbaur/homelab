{
  fetchFromGitHub,
  fetchurl,
  freetype,
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
  version = "2.6.0";

  src = fetchFromGitHub {
    owner = "bluenviron";
    repo = "mediamtx-rpicamera";
    tag = "v${finalAttrs.version}";
    hash = "sha256-opTE58PMhG0k8Y8zAeheAb6aRN0Qq+ozMDPx1yyiHT0=";
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
    libcamera
    freetype
    libjpeg
    openh264
  ];
})
