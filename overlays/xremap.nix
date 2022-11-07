{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.8";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-TwRnRcaoQHKB1Ge3NQWJ9HdtEmGoetTUti8Ti2Nuhr8=";
  };
  cargoSha256 = "sha256-EnjhQvbTeZbYjV9kIqQuhNWXSt/P33Z3Kck1co6Rrmo=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
