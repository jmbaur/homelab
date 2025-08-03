{
  stdenvNoCC,
  openscad-unstable,
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

  postInstall = ''
    mkdir -p $out/nix-support
    for file in $(find $out -type f -name '*.stl'); do
      echo "file $(basename $file) $file" >> $out/nix-support/hydra-build-products
    done
  '';

  nativeBuildInputs = [ openscad-unstable ];
}
