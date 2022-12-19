{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.11";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-ZCabZCsNmEF609GCo5BRWgUCWRv1m3vIP8DzMYMnryc=";
  };
  cargoSha256 = "sha256-PwfNfjssQGMEsCwyYxXLqbTbJwCQdZUfMOUqDsMGZS8=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
