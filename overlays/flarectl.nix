{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.56.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-nnHwW6zoiIRvZWwZIaaBVOs1fasLkBiLQ3JZdAi8f5A=";
  };
  vendorSha256 = "sha256-tYOWIeL0HPVaiWyI9YAz101w+uYfI7AvRaysXR1KOFg=";
  subPackages = [ "cmd/flarectl" ];
}
