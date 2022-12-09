{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.10";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-ZktxkypeS8nWmMWFJ4GSouVxgX7SRxuaaieEioBE/fM=";
  };
  cargoSha256 = "sha256-iN+PCuX5Sb1diub6hCz3uSdvMVpRzP6qt+5i9srKNcA=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
