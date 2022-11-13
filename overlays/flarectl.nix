{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.54.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-tf6jTW6/ZXiHxHYq6wW2u+eycqdVOb6Y0GzW6JZuQIE=";
  };
  vendorSha256 = "sha256-JNYrDVV2aHzvGSF7d7u75lrjD++fBtlY9VUmpCheCNU=";
  subPackages = [ "cmd/flarectl" ];
}
