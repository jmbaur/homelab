{ cmake
, cmocka
, fetchFromGitiles
, libftdi1
, libjaylink
, libusb1
, meson
, ninja
, pciutils
, pkg-config
, stdenv
}:
stdenv.mkDerivation {
  pname = "flashrom-cros";
  version = "2022-12-29";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "87d712d4f1b26a83db75e97485baa430b919f784";
    sha256 = "sha256-xOv3rEHfeEvAAi2NLgoQGuJAXtn47aMR6Nmg7+vQpDs=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
