{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.75.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-c2TxCSlG92eXWLY8VXBTim/kWDBnUpAaSA1+p5Sbn5I=";
  };
  vendorSha256 = "sha256-ALdT37eUszhcHjx8k9+53E9xNraESGgZl2+W1c6rWX8=";
  subPackages = [ "cmd/flarectl" ];
}
