{
  sqlite,
  lib,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "local-overlay-fixup-db";
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

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ sqlite ];

  meta = {
    description = "Program to fixup the upper Nix DB for local-overlay on A/B updated systems";
    mainProgram = "local-overlay-fixup-db";
  };
}
