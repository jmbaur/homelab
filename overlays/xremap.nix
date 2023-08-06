{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.6";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-l4erKAbf3dzxOQpzl7eIvGgQrzEsZYOGswVbz4Zh90g=";
  };
  cargoSha256 = "sha256-RABdEh+XAVm4NlaVd15aSm8p6/zcP+BUWY3Tzwtqn7E=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
