{ buildGoPackage, fetchFromGitHub, buildPackages, pkgsStatic, xz, cpio, runCommand, ... }:
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

  base = runCommand "busybox-initramfs" { nativeBuildInputs = [ cpio ]; } ''
    mkdir root; cd root
    cp -r ${pkgsStatic.busybox}/. .
    find . -print0 |
      cpio --null --create --verbose --format=newc >$out
  '';
in
buildGoPackage {
  pname = "${pname}-initramfs";
  inherit version src goPackagePath;
  nativeBuildInputs = [ xz ];
  patches = [
    ./u-root-extlinux-path.patch # allows for booting extlinux on nixos /boot/extlinux/extlinux.conf
    ./u-root-no-defaultsh.patch # just use /bin/sh
  ];
  buildPhase = ''
    GOROOT="$(go env GOROOT)" ${builder}/bin/u-root \
      -uroot-source go/src/$goPackagePath \
      -defaultsh "" \
      -uinitcmd boot \
      -base ${base} \
      -o initramfs.cpio \
      ./cmds/{core/init,boot/boot,boot/localboot}
  '';
  installPhase = ''
    xz --check=crc32 --lzma2=dict=512KiB <initramfs.cpio >$out
  '';
}
