{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.66.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-RiUYUgqjLCkhtxXUqgE5zBt4bvP+/0P4V00vSVztb4A=";
  };
  vendorSha256 = "sha256-2NZIsx2mXzb8MbDjJwmDRiCq9GuL2ST9tArj39EQrgU=";
  subPackages = [ "cmd/flarectl" ];
}
