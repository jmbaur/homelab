{
  coreutils,
  dtc,
  jq,
  lib,
  stdenv,
  ubootTools,
  util-linux,
  vboot_reference,
  writeShellApplication,
  xz,
}:

# Create a ChromeOS compatible kpart from a given NixOS
# config's toplevel output.
writeShellApplication {
  name = "chromeos-kpart";

  runtimeInputs = [
    coreutils
    dtc
    jq
    ubootTools
    util-linux
    vboot_reference
    xz
  ];

  text = ''
    declare -r keyblock=${vboot_reference}/share/vboot/devkeys/kernel.keyblock
    declare -r vbprivk=${vboot_reference}/share/vboot/devkeys/kernel_data_key.vbprivk
    declare -r fitimage_its=${./fitimage-${stdenv.hostPlatform.linuxArch}.its}
    ${lib.fileContents ./chromeos-kpart.bash}
  '';
}
