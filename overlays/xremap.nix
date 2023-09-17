{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.7";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-fypHpJTCB0SLzcIuWzJIsBSk8OHuSjmtQNNrs0HtTgM=";
  };
  cargoSha256 = "sha256-uI1gwE4EXuSzQiRmvD4YO3ziPWk73ZtKw2gtO5JEbu8=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
