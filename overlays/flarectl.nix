{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.70.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-HVQ5n18UF2nlLEQT1ks3/ca5rNZFjFF7tb2nWJ4U11g=";
  };
  vendorSha256 = "sha256-3BeOTNVaM04COzl5v4h3nxLPughR0N/5MdW071s5CUc=";
  subPackages = [ "cmd/flarectl" ];
}
