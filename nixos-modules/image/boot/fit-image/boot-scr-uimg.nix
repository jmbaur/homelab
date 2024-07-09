{
  runCommand,
  ubootTools,
  dtc,
  globalBootScript,
}:

runCommand "boot.scr.uimg"
  {
    nativeBuildInputs = [
      ubootTools
      dtc
    ];
  }
  ''
    image_its=$(mktemp)
    cat >$image_its <<EOF
    /dts-v1/;
    / {
      description = "entrypoint";
      #address-cells = <1>;
      images {
        default = "bootscript";
        bootscript {
          description = "bootscript";
          data = /incbin/("${globalBootScript}");
          type = "script";
          compression = "none";
          hash-1 {
            algo = "sha256";
          };
        };
      };
    };
    EOF

    mkimage --fit $image_its $out
  ''
