{
  chickenEggs,
  dbus,
  eggDerivation,
  fetchurl,
  lib,
  pkg-config,
}:

eggDerivation rec {
  pname = "dbus";
  version = "0.97";
  # Only published in the CHICKEN 5 egg channel.
  src = fetchurl {
    url = "https://code.call-cc.org/egg-tarballs/5/dbus/dbus-${version}.tar.gz";
    sha256 = "0a1850gark0xjn8cw1gwxgqjpk17zjmk6wc5g23ikjh9gib8ry1q";
  };
  patches = [
    ./0001-Drop-backticked-pkg-config-options.patch
    ./0002-Port-to-CHICKEN-6.patch
    ./0003-Export-arbitrary-match-rules.patch
    ./0004-Raise-on-error-replies.patch
    ./0005-Return-pointer-from-converters.patch
  ];
  separateDebugInfo = true;
  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];
  propagatedBuildInputs = with chickenEggs; [
    foreigners
    miscmacros
    srfi-18
  ];
  # The egg's backticked pkg-config options don't survive chicken-install.
  preBuild = ''
    export NIX_CFLAGS_COMPILE+=" $($PKG_CONFIG --cflags dbus-1)"
  '';
  meta.license = lib.licenses.mit;
}
