{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.73.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-wpDxsjvLFaA7TZSLn1Nt0Meqh1Pq8B7mubMh+OP5LEM=";
  };
  vendorSha256 = "sha256-NtKotBRSx67h1NwbhCfqL1hcl/WJmVQZDmHkIPrEUoE=";
  subPackages = [ "cmd/flarectl" ];
}
