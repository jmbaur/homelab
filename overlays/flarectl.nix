{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.68.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-6qU73Fcd57a+aIXQmrX+oW31hWe3VTl24NIP88rSRvc=";
  };
  vendorSha256 = "sha256-+jUaw77ICMMn5ez6Eh3fAHV7gVoc1ItH6VsDaFIRZmg=";
  subPackages = [ "cmd/flarectl" ];
}
