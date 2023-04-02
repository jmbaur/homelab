{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.64.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-yHxpmp8W9qRMNpf6HCEcyhsdaXwv+e81A5ID+igd9+0=";
  };
  vendorSha256 = "sha256-sazIN/Q3XVJW2tQUABl0nqPaC5J2kbn0tGGJoYqZM1g=";
  subPackages = [ "cmd/flarectl" ];
}
