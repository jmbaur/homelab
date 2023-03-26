{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.3";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-LeyeAd6LjapRdhOFz9kfS3+p+R+e66c1O82nvaTuCFA=";
  };
  cargoSha256 = "sha256-aElB4XlepBnQ+B9e0RFEo2dFtWJRsZksutC4wZ+DHdY=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
