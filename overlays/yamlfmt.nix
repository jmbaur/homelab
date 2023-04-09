{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "yamlfmt";
  version = "0.9.0";
  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-l081PgSAT9h2oHp1eH96XztcCLeyv1Y11l6lJhHQj1I=";
  };
  vendorSha256 = "sha256-qrHrLOfyJhsuU75arDtfOhLaLqP+GWTfX+oyLX3aea8=";
  subPackages = [ "cmd/yamlfmt" ];
}
