{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.63.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-0+bK4aXQEbMKs8x1SPALm9gdR2Ennrg2CVHk0sGDE3k=";
  };
  vendorSha256 = "sha256-IQDP4K8OOMswIFdD8/ctrNXdSEjb3/B5SFA/hiwar1Y=";
  subPackages = [ "cmd/flarectl" ];
}
