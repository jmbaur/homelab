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
  version = "2022-12-14";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "f5a7af2109f342638110d7f5b6b345164002cac1";
    sha256 = "sha256-EQuX9qy2/bfozDzxL1X65E2rTGLj1Qfzd+pbjC8Q3aU=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
