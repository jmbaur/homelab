{ lib, stdenv, cmake, cmocka, fetchFromGitiles, libftdi1, libjaylink, libusb1, meson, ninja, pciutils, pkg-config, ... }:
let
  src = lib.importJSON ./flashrom-cros.json;
in
stdenv.mkDerivation {
  pname = "flashrom-cros";
  version = builtins.substring 0 7 src.rev;

  src = fetchFromGitiles { inherit (src) url rev sha256; };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake cmocka meson ninja pkg-config ];
  buildInputs = [ libftdi1 libusb1 pciutils libjaylink ];
}
