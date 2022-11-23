{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.55.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-KIWpyrTPlARukdRLyVuotdkvlki6rnbdm1Hx0UdQQgs=";
  };
  vendorSha256 = "sha256-4TxH4GtAnHMfBoGJcsvpIlo5K8htxZsMtQr0h5srwhc=";
  subPackages = [ "cmd/flarectl" ];
}
