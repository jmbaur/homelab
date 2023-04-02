{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.8.5";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-XxkVYTpAQcNpbLgflb7HLQsy31caSbBskajNY+IKIbI=";
  };
  cargoSha256 = "sha256-DVJ/ZrFEBW3EamT3xfeXlmZMo1VpTrjA7hl51Zy6qrI=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
