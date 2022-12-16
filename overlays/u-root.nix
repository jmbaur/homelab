{ buildPackages, buildGoPackage, fetchFromGitHub, ... }:
let
  pname = "u-root";
  version = "2022-12-15";
  src = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "904692535c70f103396524ae535a2e7bc89cb75a";
    sha256 = "sha256-6BA3AVPFNm2TCvB3hzeqJIrUdVCrj0JWOzRUosy8Ilc=";
  };
  goPackagePath = "github.com/u-root/u-root";
  # u-root builder does not need to be cross-compiled
  builder = buildPackages.buildGoPackage {
    inherit pname version src goPackagePath;
    subPackages = ".";
  };
in
buildGoPackage {
  pname = "${pname}-initramfs";
  inherit version src goPackagePath;
  buildPhase = ''
    GOROOT="$(go env GOROOT)" ${builder}/bin/u-root \
      -uroot-source go/src/$goPackagePath \
      -uinitcmd=systemboot \
      core ./cmds/boot/{systemboot,localboot,fbnetboot}
  '';
  installPhase = ''
    mkdir -p $out
    cp /tmp/initramfs.*.cpio $out/initramfs.cpio
  '';
}
