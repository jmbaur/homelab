{ buildGoPackage, fetchFromGitHub, buildPackages, xz, ... }:
let
  # u-root builder does not need to be cross-compiled
  builder = buildPackages.buildGoPackage rec {
    pname = src.repo;
    version = builtins.substring 0 7 src.rev;
    src = fetchFromGitHub {
      owner = "u-root";
      repo = "u-root";
      rev = "2d7528666f509beb8f3e658adf51615fe2e3b742";
      hash = "sha256-wUEqfzxocbvPGniAP4VnIpKprVOJMpnyvmO7KIe0v7s=";
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
