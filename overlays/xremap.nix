{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.2";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-louxRX9tg0me/El4XCxDGaZkRJbYVwKwy7yIN0z1z/A=";
  };
  cargoSha256 = "sha256-5DenTsZ0f68W4wFgrGVC9ZhTAIji1zSyn2E3KkSiyH0=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
