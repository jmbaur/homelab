{ stdenv, cmake, cmocka, fetchgit, libftdi1, libjaylink, libusb1, meson, ninja, pciutils, pkg-config, ... }:
stdenv.mkDerivation rec {
  pname = "flashrom-cros";
  version = builtins.substring 0 7 src.rev;

  src = fetchgit {
    url = "https://chromium.googlesource.com/chromiumos/third_party/flashrom";
    rev = "4ce0639e77f0b0ade8c203a84226c57b4855b231";
    sha256 = "sha256-RZtJg+FNMmj1gng2+Uf/pf3dJ77c6BQe+mLNqmmIjMY=";
  };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
