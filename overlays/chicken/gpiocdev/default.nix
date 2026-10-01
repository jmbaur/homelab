{ eggDerivation, lib }:

eggDerivation {
  pname = "gpiocdev";
  version = "0.0.0";
  separateDebugInfo = true;
  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./gpiocdev.egg
      ./gpiocdev.scm
    ];
  };
  meta.platforms = lib.platforms.linux;
}
