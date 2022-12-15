{ buildGoPackage, fetchFromGitHub, ... }:
buildGoPackage {
  pname = "u-root";
  version = "2022-12-15";
  src = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "904692535c70f103396524ae535a2e7bc89cb75a";
    sha256 = "sha256-6BA3AVPFNm2TCvB3hzeqJIrUdVCrj0JWOzRUosy8Ilc=";
  };
  goPackagePath = "github.com/u-root/u-root";
  subPackages = ".";
}
