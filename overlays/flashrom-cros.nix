{ lib, stdenv, cmake, cmocka, fetchgit, libftdi1, libjaylink, libusb1, meson, ninja, pciutils, pkg-config, sphinx, bash-completion, ... }:
let
  source = lib.importJSON ./flashrom-cros-source.json;
in
stdenv.mkDerivation rec {
  pname = "flashrom-cros";
  version = builtins.substring 0 7 src.rev;

  src = fetchgit { inherit (source) url rev sha256 fetchLFS fetchSubmodules deepClone leaveDotGit; };

  dontUseCmakeConfigure = true;
  nativeBuildInputs = [ cmake meson ninja pkg-config sphinx bash-completion ];
  buildInputs = [ cmocka libftdi1 libusb1 pciutils libjaylink ];
}
