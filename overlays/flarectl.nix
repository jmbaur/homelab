{ buildGoModule, fetchFromGitHub, lib, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.49.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-VkmimyH5NYR1lEoKKf/R7WFhsKn3rc9IWlnnRWFji5g=";
  };
  vendorSha256 = "sha256-e3yww1mrXmcY1R1RjYl92/e9zpUkZ2J0EiwzM+hOAQQ=";
  subPackages = [ "cmd/flarectl" ];
}
