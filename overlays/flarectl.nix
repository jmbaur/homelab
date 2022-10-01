{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.51.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-ANUy8DujF5yBYbztHzuoVfoeNCbRvgdf4H5vRI95cBw=";
  };
  vendorSha256 = "sha256-0cQ0ZHlA4OVYG6l8G0t4uhdhUCUhOPuIcpTQJw7jO40=";
  subPackages = [ "cmd/flarectl" ];
}
