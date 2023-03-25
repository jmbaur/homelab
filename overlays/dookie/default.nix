{ rustPlatform }:
rustPlatform.buildRustPackage {
  pname = "dookie";
  version = "0.1.0";
  src = ./.;
  cargoSha256 = "sha256-gQOoaiURl2QMFTs/byZdsAc5JEFpfNzFaVsE+0rJoj4=";
}
