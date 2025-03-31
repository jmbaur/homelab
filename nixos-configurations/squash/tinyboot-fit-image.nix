{
  tinybootLinux,
  fdt,
  tinybootLoader,
  ubootTools,
  runCommand,
}:

runCommand "tinyboot-fit-image"
  {
    nativeBuildInputs = [ ubootTools ];
  }
  ''
    cp ${tinybootLinux}/zImage .
    cp ${tinybootLoader}/*.cpio .
    cp ${fdt} .

    mkimage -f ${./tinyboot.its} $out
  ''
