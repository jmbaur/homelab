{
  lib,
  uboot-clearfog_spi,
  tinybootFitImage,
}:

uboot-clearfog_spi.override {
  extraStructuredConfig = with lib.kernel; {
    FIT = yes;
    SPL_FIT = yes;
  };
}
