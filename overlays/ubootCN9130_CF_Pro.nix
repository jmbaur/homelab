{ cn913x_build, fetchFromGitHub, buildUBoot, ... }:
(buildUBoot rec {
  version = "2019.10";
  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "v${version}";
    sha256 = "sha256-NhIw4oI1HPjNBWXHJUyScq5qsJ4gx0Al7LNTa95rQTo=";
  };
  extraMeta.platforms = [ "aarch64-linux" ];
  defconfig = "sr_cn913x_cex7_defconfig";
  extraMakeFlags = [ "DEVICE_TREE=cn9130-cf-pro" ];
  filesToInstall = [ "u-boot.bin" ];
}).overrideAttrs (_: {
  # Nixpkgs has some patches for the raspberry pi that don't apply
  # cleanly to the solidrun version of u-boot.
  patches = [
    "${cn913x_build}/patches/u-boot/0001-cmd-add-tlv_eeprom-command.patch"
    "${cn913x_build}/patches/u-boot/0002-cmd-tlv_eeprom.patch"
    "${cn913x_build}/patches/u-boot/0003-cmd-tlv_eeprom-remove-use-of-global-variable-current.patch"
    "${cn913x_build}/patches/u-boot/0004-cmd-tlv_eeprom-remove-use-of-global-variable-has_bee.patch"
    "${cn913x_build}/patches/u-boot/0005-cmd-tlv_eeprom-do_tlv_eeprom-stop-using-non-api-read.patch"
    "${cn913x_build}/patches/u-boot/0006-cmd-tlv_eeprom-convert-functions-used-by-command-to-.patch"
    "${cn913x_build}/patches/u-boot/0007-cmd-tlv_eeprom-remove-empty-function-implementations.patch"
    "${cn913x_build}/patches/u-boot/0008-cmd-tlv_eeprom-split-off-tlv-library-from-command.patch"
    "${cn913x_build}/patches/u-boot/0009-lib-tlv_eeprom-add-function-for-reading-one-entry-in.patch"
    "${cn913x_build}/patches/u-boot/0010-uboot-marvell-patches.patch"
    "${cn913x_build}/patches/u-boot/0011-uboot-support-cn913x-solidrun-paltfroms.patch"
    "${cn913x_build}/patches/u-boot/0012-add-SoM-and-Carrier-eeproms.patch"
    "${cn913x_build}/patches/u-boot/0013-find-fdtfile-from-tlv-eeprom.patch"
    "${cn913x_build}/patches/u-boot/0014-octeontx2_cn913x-support-distro-boot.patch"
    "${cn913x_build}/patches/u-boot/0015-octeontx2_cn913x-remove-console-variable.patch"
    "${cn913x_build}/patches/u-boot/0016-octeontx2_cn913x-enable-mmc-partconf-command.patch"
    "${cn913x_build}/patches/u-boot/0017-uboot-add-support-cn9131-cf-solidwan.patch"
    "${cn913x_build}/patches/u-boot/0018-uboot-add-support-bldn-mbv.patch"
    "${cn913x_build}/patches/u-boot/0019-uboot-cn9131-cf-solidwan-add-carrier-eeprom.patch"
    ./ramdisk_addr_r.patch
  ];
})
