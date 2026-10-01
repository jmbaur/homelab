{
  eggDerivation,
  lib,
  qrencode,
}:

eggDerivation {
  pname = "qrencode";
  version = "0.0.0";
  separateDebugInfo = true;
  buildInputs = [ qrencode ];
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./qrencode.egg
      ./qrencode.scm
    ];
  };
}
