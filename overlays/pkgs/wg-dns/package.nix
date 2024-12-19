{ rustPlatform, lib }:

rustPlatform.buildRustPackage {
  pname = "wg-dns";
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

  meta = {
    description = "Program to update the wireguard endpoint address for endpoints with DNS names";
    mainProgram = "wg-dns";
  };
}
