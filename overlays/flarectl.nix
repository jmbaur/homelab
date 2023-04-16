{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.65.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-INDzVrY38g+SY/lNDP6x/P44YMlfTt59yV1cpHux7xo=";
  };
  vendorSha256 = "sha256-2NZIsx2mXzb8MbDjJwmDRiCq9GuL2ST9tArj39EQrgU=";
  subPackages = [ "cmd/flarectl" ];
}
