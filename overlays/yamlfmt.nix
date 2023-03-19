{ buildGoModule, fetchFromGitHub, ... }:
buildGoModule rec {
  pname = "yamlfmt";
  version = "0.8.0";
  src = fetchFromGitHub {
    owner = "google";
    repo = pname;
    rev = "v${version}";
    sha256 = "sha256-2gcB44tpYXRES0nqLfXt3Srj2NCuQ/iBdv4yxjfmrnk=";
  };
  vendorSha256 = "sha256-7Ip6dgpO3sPGXcwymYcaoFydTPIt+BmJC7UqyfltJx0=";
  subPackages = [ "cmd/yamlfmt" ];
}
