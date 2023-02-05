{ buildGoPackage, fetchFromGitHub, buildPackages, xz, ... }:
let
  # u-root builder does not need to be cross-compiled
  builder = buildPackages.buildGoPackage rec {
    pname = "u-root";
    version = "0.11.0";
    src = fetchFromGitHub {
      owner = pname;
      repo = pname;
      rev = "v${version}";
      sha256 = "sha256-IhQtIgvaoBLAPDUbgv6+G64K9KMXKQ7UOR4OKr0tp5U=";
    };
    goPackagePath = "github.com/u-root/u-root";
    subPackages = ".";
  };
in
buildGoPackage {
  pname = "${builder.pname}-initramfs";
  inherit (builder) src version goPackagePath;
  nativeBuildInputs = [ xz ];
  patches = [
    ./u-root-extlinux-path.patch # allows for booting extlinux on nixos /boot/extlinux/extlinux.conf
  ];
  buildPhase = ''
    GOROOT="$(go env GOROOT)" ${builder}/bin/u-root \
      -uroot-source go/src/$goPackagePath \
      -uinitcmd boot \
      -o initramfs.cpio \
      core ./cmds/{core/init,boot/boot,boot/localboot}
  '';
  installPhase = ''
    xz --check=crc32 --lzma2=dict=512KiB <initramfs.cpio >$out
  '';
}
