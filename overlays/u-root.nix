{ buildGoPackage, fetchFromGitHub, buildPackages, writeText, ... }:
let
  pname = "u-root";
  version = "2022-12-21";
  src = fetchFromGitHub {
    owner = "u-root";
    repo = "u-root";
    rev = "b02caf19d3072bfecd00012bf586b6a729d75639";
    sha256 = "sha256-v5lX6jCmFs1TURv3F5gbfTSSG4Mp2roRRx3FBJLazLk=";
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
    ./u-root-more-stdin.patch # allow stdin to be used for more
  ];
  buildPhase = ''
    mkdir -p $out
    GOROOT="$(go env GOROOT)" ${builder}/bin/u-root \
      -uroot-source go/src/$goPackagePath \
      -files "${elvishrc}:etc/rc.elv" \
      -o $out/initramfs.cpio \
      -uinitcmd=boot \
      core ./cmds/boot/boot
  '';
  dontInstall = true;
}
