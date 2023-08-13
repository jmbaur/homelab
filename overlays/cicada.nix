{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.38";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "sha256-YZICLcjV7fli2hKQ9HF5ou0tf/yWdCTqjIfw9Evs7KI=";
  };

  cargoSha256 = "sha256-xzn/4cN8RLOzraVTLmK+YTymaKfgRpZM95WPJwX8G/U=";

  doCheck = false;
}
