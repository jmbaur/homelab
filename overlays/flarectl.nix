{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.67.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-uP8+MDrt9lWftY5SytOAdvAV+Hdm1EvmAU3P3jHecgQ=";
  };
  vendorSha256 = "sha256-G0kdYuxOB8Nfsix3ti400zts40Sf2Nz62sIkZhjmPZc=";
  subPackages = [ "cmd/flarectl" ];
}
