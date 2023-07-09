{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.72.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-SDK0jTj058sVY+oIvaX0iZDMa8v3kVnjIWu8aFFbpmU=";
  };
  vendorSha256 = "sha256-3BeOTNVaM04COzl5v4h3nxLPughR0N/5MdW071s5CUc=";
  subPackages = [ "cmd/flarectl" ];
}
