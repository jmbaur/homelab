{
  eggDerivation,
  lib,
  libsodium,
}:

eggDerivation {
  pname = "libsodium";
  version = "0.0.0";
  separateDebugInfo = true;
  buildInputs = [ libsodium ];
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./libsodium.egg
      ./libsodium.scm
    ];
  };
}
