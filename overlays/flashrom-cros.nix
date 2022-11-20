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
  version = "2022-11-15";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "64a7c1d2f75a717c47aeb3edb4d2bba73d7b36ac";
    sha256 = "sha256-Zw736C7cBKO8KwuTXWhn30yiZ2J8vMsv7q8qt6IROQw=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
