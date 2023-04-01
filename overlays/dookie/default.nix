{ rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "dookie";
  version = "0.1.0";
  src = ./.;
  cargoLock.lockFile = ./Cargo.lock;
}
