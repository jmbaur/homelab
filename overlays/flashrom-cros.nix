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
  version = "2022-12-17";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "71ede00efd482f497822841375211fcd5cf00d6b";
    sha256 = "sha256-98na7SaKX4/ZjUhE56AvAN0WQtcEHtYrDBGMiLOBFwo=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
