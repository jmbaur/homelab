{
  armTrustedFirmwareImx8mp,
  pkgsBuildBuild,
  buildUBoot,
  fetchFromGitHub,
}:

(buildUBoot {
  defconfig = "imx8mp_adlink_lec_defconfig";
  version = "v2025.07-rc5";

  src = fetchFromGitHub {
    owner = "u-boot";
    repo = "u-boot";
    rev = "v2025.07-rc5";
    hash = "sha256-tIQMeszvDlpu8Of3vluoA2T0OgVWaAKyFMj50U2y+j0=";
  };

  extraMakeFlags = [ "BL31=${armTrustedFirmwareImx8mp}/bl31.bin" ];

  patches = [ ./imx8mp-adlink-lec-support.patch ];

  preBuild = ''
    install -Dm0644 ${pkgsBuildBuild.imxFirmware}/* .
  '';

  filesToInstall = [
    "flash.bin"
    ".config"
  ];
}).overrideAttrs
  (old: {
    nativeBuildInputs = (old.nativeBuildInputs or [ ]) ++ [ pkgsBuildBuild.efitools ];
  })
