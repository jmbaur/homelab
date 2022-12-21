{ lib, edk2, python3, libuuid, nasm, ... }:
edk2.mkDerivation "UefiPayloadPkg/UefiPayloadPkg.dsc" (_: {
  pname = "edk2-uefipayloadpkg";
  inherit (edk2) version;
  PYTHON_COMMAND = "${lib.getBin python3}/bin/python3";
  # NOTE: these were copied from coreboot's edk2 Makefile
  buildFlags = [
    "--pcd gEfiMdeModulePkgTokenSpaceGuid.PcdConOutColumn=0"
    "--pcd gEfiMdeModulePkgTokenSpaceGuid.PcdConOutRow=0"
    "--pcd gEfiMdeModulePkgTokenSpaceGuid.PcdSetupConOutColumn=0"
    "--pcd gEfiMdeModulePkgTokenSpaceGuid.PcdSetupConOutRow=0"
    "--pcd gEfiMdePkgTokenSpaceGuid.PcdPciExpressBaseAddress=0xc0000000" # TODO(jared): device-specific
    "--pcd gEfiMdePkgTokenSpaceGuid.PcdPciExpressBaseSize=0x10000000" # TODO(jared): device-specific
    "-D ABOVE_4G_MEMORY=FALSE"
    "-D BOOTLOADER=COREBOOT"
    "-D BOOTSPLASH_IMAGE=TRUE"
    "-D PLATFORM_BOOT_TIMEOUT=3"
    "-D PRIORITIZE_INTERNAL=TRUE"
    "-D PS2_KEYBOARD_ENABLE=TRUE"
    "-D SD_MMC_TIMEOUT=1000000"
    "-D VARIABLE_SUPPORT=SMMSTORE"
    "-a IA32" # TODO(jared): architecture-specific
    "-s"
  ];
  nativeBuildInputs = [ nasm ];
  buildInputs = [ libuuid ];
  dontPatchELF = true;
  dontStrip = true;
})
