{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.57.1";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-JclZsM6y5VPHbbDEmMW8Lv9EtSsLsGlIKz/+pesz2do=";
  };
  vendorSha256 = "sha256-NptGNuOYvsylaTevgB5QVzVbPQAUCHYDt33+pJ+ijyU=";
  subPackages = [ "cmd/flarectl" ];
}
