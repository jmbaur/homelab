{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.61.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-s+jqlw/ma6nah+qkdBxA8CpATPuLGC7iDux7SVaBWbU=";
  };
  vendorSha256 = "sha256-c3MNTLKgy9olUfVMlkd1ICsopRosoevRtaUNTO3AR1E=";
  subPackages = [ "cmd/flarectl" ];
}
