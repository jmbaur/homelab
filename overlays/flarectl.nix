{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.53.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-FdKxYaX4SGUIdU55xRswRr9C2cFkK9LI6J8i1WoRORE=";
  };
  vendorSha256 = "sha256-LxxSSvh3RPGD2oc+op/68kflGs9pU7RHWyiNz870Fmk=";
  subPackages = [ "cmd/flarectl" ];
}
