{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.9";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-BFngW889qO0uhTSvi+rhfrmqzID6uj34IrgN5eWEWWc=";
  };
  cargoSha256 = "sha256-93zGIR+1zOyAftC5b/Ns1XuhaLCZX5eSCBj4qEC28HU=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
