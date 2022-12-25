{ rustPlatform, fetchFromGitHub, buildFeatures ? [ "sway" ], ... }:
rustPlatform.buildRustPackage rec {
  pname = "xremap";
  version = "0.7.14";
  src = fetchFromGitHub {
    owner = "k0kubun";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-6adOhOG4XEz19uKL/f9r39OyEiQUOTbch4UhfgDm6u0=";
  };
  cargoSha256 = "sha256-CRjXHVcfelCjxe2Rg/MNIXseL8TdlUjsmD9xPZyvukY=";
  buildNoDefaultFeatures = true;
  inherit buildFeatures;
}
