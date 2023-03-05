{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.62.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-CLNOAcsby7JU4PrpoIx0K4Zw7Qy7zbYDXzPdGdKY6eE=";
  };
  vendorSha256 = "sha256-6PzAUnvs00QX4dZyr93Gb8yEN3GhpEB0RwJHQIS5edg=";
  subPackages = [ "cmd/flarectl" ];
}
