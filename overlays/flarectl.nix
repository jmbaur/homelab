{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.78.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-olqE6oaQymclcgvU6dkf+DkCBrOYTMW5PvVsVPuoCH8=";
  };
  vendorSha256 = "sha256-xAo8FuedGo2v7y8wHYWJLNuTJzNz1XQJ3igDXSnBePg=";
  subPackages = [ "cmd/flarectl" ];
}
