# Based on https://github.com/NixOS/nixpkgs/pull/281803
{
  stdenv,
  fetchFromGitHub,
  lib,
  makeWrapper,
  meson,
  ninja,
  pkg-config,
  boost,
  ffmpeg,
  libcamera,
  libdrm,
  libepoxy,
  libexif,
  libjpeg,
  libpng,
  libtiff,
  libX11,
}:

stdenv.mkDerivation (finalAttrs: {
  pname = "rpicam-apps";
  version = "1.11.0";

  src = fetchFromGitHub {
    owner = "raspberrypi";
    repo = "rpicam-apps";
    rev = "v${finalAttrs.version}";
    hash = "sha256-3f0ThN4C9ZZ/6Is51Q6QA2tnEDnLKCLbxlCNqsGzw14=";
  };

  buildInputs = [
    boost
    ffmpeg
    libX11
    libcamera
    libdrm
    libepoxy # GLES/EGL preview window
    libexif
    libjpeg
    libpng
    libtiff
  ];

  nativeBuildInputs = [
    makeWrapper
    meson
    ninja
    pkg-config
  ];

  # Meson is no longer able to pick up Boost automatically.
  # https://github.com/NixOS/nixpkgs/issues/86131
  BOOST_INCLUDEDIR = "${lib.getDev boost}/include";
  BOOST_LIBRARYDIR = "${lib.getLib boost}/lib";

  env.NIX_CFLAGS_COMPILE = toString [
    "-Wno-error=deprecated-declarations"
  ];

  # See all options here: https://github.com/raspberrypi/rpicam-apps/blob/main/meson_options.txt
  mesonFlags = [
    "-Denable_drm=disabled"
    "-Denable_egl=disabled"
    "-Denable_hailo=disabled"
    "-Denable_qt=disabled"
  ];
})
