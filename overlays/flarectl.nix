{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.60.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-/ERzjd+O6pnfXaHeGglBO175fX/6s0H/wYlh8dFPb5w=";
  };
  vendorSha256 = "sha256-e4kSANf4F2YuC3+Z1lHqlE+wFnZIvvdxzD06yws2J5w=";
  subPackages = [ "cmd/flarectl" ];
}
