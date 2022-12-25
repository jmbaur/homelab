{ lib, stdenv, cn913x_build, linuxKernel, ... }:
let
  base = linuxKernel.kernels.linux_5_15;
in
(linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (base) src version modDirVersion extraMakeFlags;
  kernelPatches = base.kernelPatches ++ [
    {
      name = "0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-";
      patch = "${cn913x_build}/patches/linux/0001-arm64-dts-cn913x-add-cn913x-based-COM-express-type-.patch";
    }
    {
      name = "0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the";
      patch = "${cn913x_build}/patches/linux/0002-arm64-dts-cn913x-add-cn913x-COM-device-trees-to-the.patch";
    }
    {
      name = "0004-dts-update-device-trees-to-cn913x-rev-1";
      patch = "${cn913x_build}/patches/linux/0004-dts-update-device-trees-to-cn913x-rev-1.1.patch";
    }
    {
      name = "0005-DTS-update-cn9130-device-tree";
      patch = "${cn913x_build}/patches/linux/0005-DTS-update-cn9130-device-tree.patch";
    }
    {
      name = "0007-update-spi-clock-frequency-to-10MHz";
      patch = "${cn913x_build}/patches/linux/0007-update-spi-clock-frequency-to-10MHz.patch";
    }
    {
      name = "0009-dts-cn9130-som-for-clearfog-base-and-pro";
      patch = "${cn913x_build}/patches/linux/0009-dts-cn9130-som-for-clearfog-base-and-pro.patch";
    }
    {
      name = "0010-dts-add-usb2-support-and-interrupt-btn";
      patch = "${cn913x_build}/patches/linux/0010-dts-add-usb2-support-and-interrupt-btn.patch";
    }
    {
      name = "0011-linux-add-support-cn9131-cf-solidwan";
      patch = "${cn913x_build}/patches/linux/0011-linux-add-support-cn9131-cf-solidwan.patch";
    }
    {
      name = "0012-linux-add-support-cn9131-bldn-mbv";
      patch = "${cn913x_build}/patches/linux/0012-linux-add-support-cn9131-bldn-mbv.patch";
    }
    {
      name = "0013-cpufreq-armada-enable-ap807-cpu-clk";
      patch = "${cn913x_build}/patches/linux/0013-cpufreq-armada-enable-ap807-cpu-clk.patch";
    }
    {
      name = "0014-thermal-armada-ap806-Thermal-values-updated";
      patch = "${cn913x_build}/patches/linux/0014-thermal-armada-ap806-Thermal-values-updated.patch";
    }
    {
      name = "0015-Documentation-bindings-armada-thermal-Added-armada-a";
      patch = "${cn913x_build}/patches/linux/0015-Documentation-bindings-armada-thermal-Added-armada-a.patch";
    }
    {
      name = "0016-thermal-armada-ap807-Thermal-data-structure-added";
      patch = "${cn913x_build}/patches/linux/0016-thermal-armada-ap807-Thermal-data-structure-added.patch";
    }
    {
      name = "0017-dts-armada-ap807-updated-thermal-compatibility";
      patch = "${cn913x_build}/patches/linux/0017-dts-armada-ap807-updated-thermal-compatibility.patch";
    }
    {
      name = "0018-DPDK-support-for-MVPP2";
      patch = "${cn913x_build}/patches/linux/0018-DPDK-support-for-MVPP2.patch";
    }
    {
      name = "0019-arm64-dts-cn9130-clearfog-base-add-m.2-gpios";
      patch = "${cn913x_build}/patches/linux/0019-arm64-dts-cn9130-clearfog-base-add-m.2-gpios.patch";
    }
  ];
  configfile = ./cn913x.config;
  allowImportFromDerivation = true;
}).overrideAttrs (old: {
  passthru = old.passthru // { config = old.passthru.config // { DTB = true; }; };
})
