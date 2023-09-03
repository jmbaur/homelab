{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "yamlfmt";
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-+xlPXHM/4blnm09OcMSpvVTLJy38U4xkVMd3Ea2scyU=";
  };
  vendorSha256 = "sha256-qrHrLOfyJhsuU75arDtfOhLaLqP+GWTfX+oyLX3aea8=";
  subPackages = [ "cmd/yamlfmt" ];
}
