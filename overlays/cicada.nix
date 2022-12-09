{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.34";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "sha256-gv+saSL0v531CGoDCpqUrdgwJeG1wAdGnh8lMIf4vvE=";
  };

  cargoSha256 = "sha256-ijEXi2O3yi1ccOO5W6ABDysVvz16FiBIsfZz0yv+Z5I=";

  doCheck = false;
}
