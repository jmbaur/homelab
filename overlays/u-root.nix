{ buildPackages, buildGoPackage, fetchFromGitHub, ... }:
let
  pname = "u-root";
  version = "2022-12-18";
  src = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "bac9c581f8d94a2b0df97e84001287f18fd12370";
    sha256 = "sha256-Yhd6jxO7DmBKJww41xCQ5f9H11geSwnrfWaSfRP117E=";
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
