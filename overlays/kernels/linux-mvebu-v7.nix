{ buildLinux, linuxKernel, ... }:
buildLinux {
  inherit (linuxKernel.kernels.linux_6_1)
    src version modDirVersion kernelPatches extraMakeFlags;
  defconfig = "mvebu_v7_defconfig";
}
