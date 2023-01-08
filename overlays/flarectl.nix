{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.58.1";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-EJTdlMahMt8sHwY6kFId1P16+N942/U5iqx59TPcmRw=";
  };
  vendorSha256 = "sha256-SNRthHZv35v8jw8bGB6LKtaXbvu4ul+Kyuz6Hy89VAA=";
  subPackages = [ "cmd/flarectl" ];
}
