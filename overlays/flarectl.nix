{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.74.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-pnZof+D+NWKyhUUAVIUWjrqxrLCbxCpRFMgDH8d+2/k=";
  };
  vendorSha256 = "sha256-NtKotBRSx67h1NwbhCfqL1hcl/WJmVQZDmHkIPrEUoE=";
  subPackages = [ "cmd/flarectl" ];
}
