# Based on https://github.com/NixOS/nixpkgs/pull/281803
{
  boost,
  fetchFromGitHub,
  ffmpeg_7-headless,
  lib,
  libcamera,
  libdrm,
  libexif,
  libjpeg,
  libpng,
  libtiff,
  makeWrapper,
  meson,
  ninja,
  pkg-config,
  stdenv,
}:

let
  ffmpeg = ffmpeg_7-headless.overrideAttrs {
    version = "7.1.2";
    src = fetchFromGitHub {
      owner = "jc-kynesim";
      repo = "rpi-ffmpeg";
      rev = "de943d66dab18e89fc10c74459bea1d787edc49d";
      hash = "sha256-Qbgos7uzYXF5E557kR2EXhX9eJRmO0LVmSE2NOpEZY0=";
    };
  };
in
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
    libcamera
    libdrm
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
