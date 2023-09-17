{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "flarectl";
  version = "0.77.0";
  src = fetchFromGitHub {
    owner = "cloudflare";
    repo = "cloudflare-go";
    rev = "v${version}";
    sha256 = "sha256-kHAY+/e/08Fs/HiZTswX4Ac0/CTuSesJVEIsBvWxcUM=";
  };
  vendorSha256 = "sha256-xAo8FuedGo2v7y8wHYWJLNuTJzNz1XQJ3igDXSnBePg=";
  subPackages = [ "cmd/flarectl" ];
}
