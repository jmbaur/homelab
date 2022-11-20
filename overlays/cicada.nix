{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.33";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "sha256-eqEOVJuP2NzZiKMfq9eoNzyztd2exV9orGm1eKg7tFc=";
  };

  cargoSha256 = "sha256-9ld07oKQIVE4WIcLuJjJnnmkR6mtIPz7hacpp1OMvfI=";

  doCheck = false;
}
