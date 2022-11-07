{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "yamlfmt";
  version = "0.6.0";
  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-6ky3QU/WPKHRaC57jMm0kOuEytOdDEaFzETio3eiy/Q=";
  };
  vendorSha256 = "sha256-dIf4YHaKV07A2pzkRrnZHuuTMuQriGgPPKu848QTnXs=";
  subPackages = [ "cmd/yamlfmt" ];
}
