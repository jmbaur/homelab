{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "u-root";
  version = "0.10.0";
  src = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "v${version}";
    sha256 = "sha256-EUpBHiJ13ubxYU9p9PXrv2Rqz09W16gCOMEXylhPayo=";
  };
  vendorSha256 = null;
  subPackages = ".";
}
