{ buildGoModule, fetchFromGitHub, lib, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.50.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "00kd55n58ddrmw6y046gz9fym99j0agb8nq7kgxkr3wsiajyz4md";
  };
  vendorSha256 = "sha256-0cQ0ZHlA4OVYG6l8G0t4uhdhUCUhOPuIcpTQJw7jO40=";
  subPackages = [ "cmd/flarectl" ];
}
