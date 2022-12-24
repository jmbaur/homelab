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
  version = "2022-12-22";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "310b87378ec5af3c5f6def8fcced2fdcd020ba1e";
    sha256 = "sha256-ckKxjOOcxa70uzvTuv7/NubDntcYLjX+VuE0BOImSqQ=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
