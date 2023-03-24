{ stdenv, cmake, cmocka, fetchgit, libftdi1, libjaylink, libusb1, meson, ninja, pciutils, pkg-config, sphinx, bash-completion, ... }:
stdenv.mkDerivation rec {
  pname = "flashrom-cros";
  version = builtins.substring 0 7 src.rev;

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "0b9f06df7269182821b695e9f5d745855fa252c0";
    sha256 = "sha256-GP16RB92tl1mmdOqPGRoDf5xNkskdcydhMIMZbilYvw=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake meson ninja pkg-config sphinx bash-completion ];
  buildInputs = [ cmocka libftdi1 libusb1 pciutils libjaylink ];
}
