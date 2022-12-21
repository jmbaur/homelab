{ buildGoPackage, fetchFromGitHub, buildPackages, writeText, ... }:
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
  elvishrc = writeText "rc.elv" ''
    use readline-binding
  '';
in
buildGoPackage {
  pname = "${pname}-initramfs";
  inherit version src goPackagePath;
  patches = [
    ./u-root-extlinux-path.patch # allows for booting extlinux on nixos /boot/extlinux/extlinux.conf
    ./u-root-elvish-etc-rc.patch # read elvish rc.elv from /etc/rc.elv
  ];
  buildPhase = ''
    mkdir -p $out
    GOROOT="$(go env GOROOT)" ${builder}/bin/u-root \
      -uroot-source go/src/$goPackagePath \
      -files "${elvishrc}:etc/rc.elv" \
      -o $out/initramfs.cpio \
      -uinitcmd=systemboot \
      core ./cmds/boot/{boot,systemboot,localboot,fbnetboot}
  '';
  dontInstall = true;
}
