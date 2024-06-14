# Write a single-file, dependency-free rust program.
#
# Similar to `pkgs.writers.writeRustBin`, except you get to use all the
# features that Cargo and `rustPlatform.buildRustPackage` provides (such as
# unit testing and cross-compilation support).

{
  rustPlatform,
  writeText,
  runCommand,
}:

pname: source:
let
  version = "0.1.0"; # constant version
in
rustPlatform.buildRustPackage {
  inherit pname version;

  cargoVendorDir = "vendor";

  src = runCommand "${pname}-src" { } ''
    mkdir -p $out/{vendor,src}

    cp ${source} $out/src/main.rs

    cat >$out/Cargo.toml <<EOF
    [package]
    name = "${pname}"
    version = "${version}"
    edition = "2021"
    EOF

    cat >$out/Cargo.lock <<EOF
    version = 3
    [[package]]
    name = "${pname}"
    version = "${version}"
    EOF
  '';

  meta.mainProgram = pname;
}
