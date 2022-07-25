{ buildGoModule, fetchFromGitHub }:
buildGoModule {
  name = "coredns-utils";
  src = fetchFromGitHub {
    owner = "coredns";
    repo = "coredns-utils";
    rev = "c07df082698203e12b1b31dea9c6183cc676833e";
    sha256 = "03mq6cjr9pmdm7j02vivrpxj4m6v9hkkrz1ik0kf6sxfk8rvmlb3";
  };
  vendorSha256 = "sha256-Q+eJk4Tmv0zxOrfpnh2GiSDiCX0qFSZmczekigBheHo=";
  CGO_ENABLED = 0;
}
