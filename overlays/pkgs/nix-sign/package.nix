{
  lib,
  libsodium,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "nix-sign";
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
  buildInputs = [ libsodium ];

  meta = {
    description = "Program to use nix-store signing keys to sign arbitrary data";
    mainProgram = "nix-sign";
  };
}
