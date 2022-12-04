{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.9";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-644ZNdlYj6GBavDD7iDWnFEeNR+eSU9ueLAU2gR9hPg=";
  };
  cargoSha256 = "sha256-/+P8PinHlk93K8ERNYHKpQJ6Pluc8KXo3XNPM91mU6o=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
