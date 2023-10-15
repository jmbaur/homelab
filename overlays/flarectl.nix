{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.79.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-R/6byu73Gc291AdQSNnYlPsHx5uV16g0k6ZPSDX/Pqk=";
  };
  vendorSha256 = "sha256-gQxHJNPLVcnilMIv4drDCcQ8QJCyuZ6vejsuo0elIPw=";
  subPackages = [ "cmd/flarectl" ];
}
