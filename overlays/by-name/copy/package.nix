{
  lib,
  sbcl,
  stdenv,
}:

stdenv.mkDerivation {
  pname = "copy";
  version = "0.0.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.difference ./. ./package.nix;
  };

  nativeBuildInputs = [ sbcl ];

  dontStrip = true;

  meta.mainProgram = "copy";
}
