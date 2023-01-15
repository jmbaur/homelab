{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.0";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-uHLzTXHB8/o/gO/ujWwIM/V5Ob23D2Har9S0o09tApg=";
  };
  cargoSha256 = "sha256-YmR+pRi02T+BVzf6+FLuLhwcxPxr+jQnl1tjIejtf04=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
