{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.69.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-BGyrtLN5p2Aw3xccLwsD93SUYcgwcW4zdyOhPyPZuBs=";
  };
  vendorSha256 = "sha256-O1bPTswEszWghY9o37AIR3fv90dOhjiWpxLjz7MlEYA=";
  subPackages = [ "cmd/flarectl" ];
}
