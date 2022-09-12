{ cn913x_build
, ubootCN9130_CF_Pro
, symlinkJoin
, fetchgit
, fetchFromGitHub
, buildArmTrustedFirmware
, ...
}:
(buildArmTrustedFirmware rec {
  platform = "t9130";
  extraMeta.platforms = [ "aarch64-linux" ];
  filesToInstall = [ "build/${platform}/release/flash-image.bin" ];
  extraMakeFlags = [
    "USE_COHERENT_MEM=0"
    "LOG_LEVEL=20"
    "MV_DDR_PATH=/tmp/mv_ddr_path"
    "CP_NUM=1" # clearfog pro
    "all"
    "fip"
  ];
}).overrideAttrs (old: rec {
  version = "00ad74c7afe67b2ffaf08300710f18d3dafebb45";
  src = fetchFromGitHub {
    owner = "ARM-software";
    repo = "arm-trusted-firmware";
    rev = version;
    sha256 = "sha256-kHI6H1yym8nWWmLMNOOLUbdtdyNPdNEvimq8EdW0nZw=";
  };
  patches = old.patches ++ [
    "${cn913x_build}/patches/arm-trusted-firmware/0001-ddr-spd-read-failover-to-defualt-config.patch"
    "${cn913x_build}/patches/arm-trusted-firmware/0002-som-sdp-failover-using-crc-verification.patch"
  ];
  preBuild =
    let
      # TODO(jared): put this in flake inputs
      # https://github.com/ARM-software/arm-trusted-firmware/blob/master/docs/plat/marvell/armada/build.rst#tf-a-build-instructions-for-marvell-platforms
      # ATF's build process does some nasty things and needs the .git
      # directory.
      marvell-embedded-processors = fetchgit {
        leaveDotGit = true;
        url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
        rev = "305d923e6bc4236cd3b902f6679b0aef9e5fa52d";
        sha256 = "sha256-d9tS0ajHGzVEi1XJzdu0dCvfeEHSPVCrfBqV8qLqC5c=";
      };
    in
    ''
      cp -r ${marvell-embedded-processors} /tmp/mv_ddr_path
      ls -alh /tmp/mv_ddr_path
    '';
  BL33 = "${symlinkJoin {
            name = "armTrustedFirmwareCN9130_CF_Pro-BL33";
            paths = [ ubootCN9130_CF_Pro.src ubootCN9130_CF_Pro ];
          }}/u-boot.bin";
  SCP_BL2 = "${cn913x_build}/binaries/atf/mrvl_scp_bl2.img";
})
