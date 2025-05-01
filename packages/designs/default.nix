{
  stdenvNoCC,
  openscad,
  lib,
}:

stdenvNoCC.mkDerivation {
  name = "homelab-designs";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./src
      ./Makefile
    ];
  };

  nativeBuildInputs = [ openscad ];
}
