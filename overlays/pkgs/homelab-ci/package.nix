{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "homelab-ci";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.lock
      ./Cargo.toml
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta.description = "Poor man's CI";
}
