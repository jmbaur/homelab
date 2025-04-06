{
  lib,
  uboot-clearfog_spi,
  tinybootFitImage,
}:

(uboot-clearfog_spi.override {
  extraStructuredConfig = with lib.kernel; {
    FIT = yes;
    SPL_FIT = yes;
  };
}).overrideAttrs
  (old: {
    postBuild =
      (old.preBuild or "")
      + ''
        cp ${tinybootFitImage} u-boot.bin
        make -j$NIX_BUILD_CORES $makeFlags
      '';
  })
