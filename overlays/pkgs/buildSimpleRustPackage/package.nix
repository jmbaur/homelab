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
  cargoToml = writeText "${pname}-Cargo.toml" ''
    [package]
    name = "${pname}"
    version = "${version}"
    edition = "2021"
  '';
  cargoLock = writeText "${pname}-Cargo.lock" ''
    version = 3
    [[package]]
    name = "${pname}"
    version = "${version}"
  '';
in
rustPlatform.buildRustPackage {
  inherit pname version;

  cargoVendorDir = "vendor";

  src = runCommand "${pname}-src" { } ''
    mkdir -p $out/{vendor,src}
    ln -s ${cargoToml} $out/Cargo.toml
    ln -s ${cargoLock} $out/Cargo.lock
    ln -s ${source} $out/src/main.rs
  '';

  meta.mainProgram = pname;
}
