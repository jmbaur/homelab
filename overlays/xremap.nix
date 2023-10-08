{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.11";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-aapCb1AsMNFK1ffiqxs2SGYXQRjehXclKthjAub286w=";
  };
  cargoSha256 = "sha256-n9wm6ZButiA8rzWmINLSLEA6YLEoFA8V/oEkq5di8y8=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
