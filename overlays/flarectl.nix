{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.59.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-0IJpEtxvAOAVjb+hAX9kr6oAy33waHnKQWJ3fgxAKRU=";
  };
  vendorSha256 = "sha256-SNRthHZv35v8jw8bGB6LKtaXbvu4ul+Kyuz6Hy89VAA=";
  subPackages = [ "cmd/flarectl" ];
}
