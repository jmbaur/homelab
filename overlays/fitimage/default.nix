{ lib, runCommand, ubootTools, dtc, xz, rsync, ... }:

# NOTE: dtbs expected to be of the form:
# [ { pattern = "foo*"; } { path = "path/to/board.dtb"; } ]
{ boardName, kernel, dtbs ? [ ], initramfs }:
let
  nativeBuildInputs = [ rsync ubootTools dtc xz ];
  copyDtbs = lib.concatStringsSep "\n" (map
    (dtb:
      let pattern = lib.attrByPath [ "pattern" ] null dtb; in
      if pattern != null then ''
        find -L ${kernel}/dtbs -type f -name '${pattern}' -print0 |
          xargs -0 -I {} rsync -a {} dtbs
      '' else "ln -s ${dtb.path} dtbs")
    dtbs);
  fitimage = runCommand "fitimage-${boardName}" { inherit nativeBuildInputs; } ''
    mkdir -p dtbs $out
    lzma --threads 0 <${kernel}/Image >Image.lzma
    xz --test <${initramfs}
    cp ${initramfs} initramfs.cpio.xz
    ${copyDtbs}
    bash ${./make-image-its.bash} > image.its
    mkimage -f image.its $out/uImage
  '';
in
fitimage.overrideAttrs (old: {
  passthru = (old.passthru or { }) // { inherit boardName; };
})
