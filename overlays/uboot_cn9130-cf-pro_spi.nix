{ fetchurl, runCommand, ... }:
let
  uboot = fetchurl {
    url = "https://solid-run-images.sos-de-fra-1.exo.io/CN913x/cn913x_build/20221107-cead42e/u-boot/u-boot-cn9130-cf-pro-spi.bin";
    sha256 = "sha256-OS67tgkpeADV6lNqX50cpdqDjXrYV6Nl2SywPaV+S4Y=";
  };
in
runCommand "uboot_cn9130-cf-pro" { } ''
  mkdir -p $out
  dd if=/dev/zero of=spi.img bs=8M count=1
  dd if=${uboot} of=spi.img conv=notrunc
  cp spi.img $out/
''
