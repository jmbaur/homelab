{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.80.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-Dks5tF+mHVmtj8Uh8eK50ZPZTW8p65Da08EHUnLfF7g=";
  };
  vendorSha256 = "sha256-gQxHJNPLVcnilMIv4drDCcQ8QJCyuZ6vejsuo0elIPw=";
  subPackages = [ "cmd/flarectl" ];
}
