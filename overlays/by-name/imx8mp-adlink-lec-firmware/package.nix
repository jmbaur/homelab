{
  armTrustedFirmwareImx8mp,
  imxFirmware,
  makeUBoot,
}:

makeUBoot {
  boardName = "imx8mp_adlink_lec";

  artifacts = [ "flash.bin" ];

  makeFlags = [ "BL31=${armTrustedFirmwareImx8mp}/bl31.bin" ];

  patches = [ ./imx8mp-adlink-lec-support.patch ];

  preBuild = ''
    install -Dm0644 ${imxFirmware}/* .
  '';
}
