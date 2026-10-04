{
  chickenEggs,
  dbus,
  eggDerivation,
  fetchurl,
  lib,
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
  # The runtime closure: libdbus plus the eggs the dbus egg imports. Only
  # propagated inputs reach the programs that use this egg, which is what
  # puts them in the wrapper's CHICKEN_REPOSITORY_PATH; the -L flag in the
  # egg file's link-options and the .so's runpath come from here too.
  propagatedBuildInputs = [ dbus.lib ]
    ++ (with chickenEggs; [
      foreigners
      miscmacros
      srfi-18
    ]);
  # The FFI code includes <dbus/dbus.h>, which lives in the dev output; a
  # build-time-only dependency, so it stays out of the runtime closure.
  depsBuildTarget = [ dbus.dev ];
  # The egg's backticked pkg-config options don't survive chicken-install.
  preBuild = ''
    export NIX_CFLAGS_COMPILE+=" -I${dbus.dev}/include/dbus-1.0 -I${dbus.lib}/lib/dbus-1.0/include"
  '';
  meta.license = lib.licenses.mit;
}
