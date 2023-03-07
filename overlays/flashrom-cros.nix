{ stdenv, cmake, cmocka, fetchgit, libftdi1, libjaylink, libusb1, meson, ninja, pciutils, pkg-config, ... }:
stdenv.mkDerivation rec {
  pname = "flashrom-cros";
  version = builtins.substring 0 7 src.rev;

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "e51545c9aba3a54ecf5b1d59f5b5309c6dd6bc19";
    sha256 = "sha256-gxGEtEKt/+kMjRLUbuGA6CvMNl3w1zeOkggg1ABP5xI=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake meson ninja pkg-config ];
  buildInputs = [ cmocka libftdi1 libusb1 pciutils libjaylink ];
}
