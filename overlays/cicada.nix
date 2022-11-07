{ rustPlatform, fetchFromGitHub, ... }:
rustPlatform.buildRustPackage rec {
  pname = "cicada";
  version = "0.9.32";

  src = fetchFromGitHub {
    owner = "mitnk";
    repo = "cicada";
    rev = "v${version}";
    sha256 = "1hp9g3zr6xl9hy4hyixbd96hj08pbn7zcsaw8vngxsmp84s7w0dj";
  };

  cargoSha256 = "sha256-TynSTa7l37liw9wPl8NJ7KaX3DntLYgOSW6DjuFjd7U=";

  doCheck = false;
}
