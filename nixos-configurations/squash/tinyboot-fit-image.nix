{
  dtc,
  fdt,
  runCommand,
  tinybootLinux,
  tinybootLoader,
  ubootTools,
}:

runCommand "tinyboot-fit-image"
  {
    nativeBuildInputs = [
      dtc
      ubootTools
    ];
  }
  ''
    cp ${tinybootLinux}/zImage .
    cp ${tinybootLoader}/*.cpio .
    cp ${fdt} .
    cp ${./tinyboot.its} tinyboot.its

    mkimage -f ./tinyboot.its $out
  ''
