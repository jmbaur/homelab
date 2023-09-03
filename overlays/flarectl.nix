{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.76.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-aVu1hcmNgEWtMwXRA8exYjv9NehBmhOZY9iVO0NGV3w=";
  };
  vendorSha256 = "sha256-ALdT37eUszhcHjx8k9+53E9xNraESGgZl2+W1c6rWX8=";
  subPackages = [ "cmd/flarectl" ];
}
