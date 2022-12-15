{ lib, stdenv, linuxKernel, u-root, ... }:
let
  initramfs = u-root.overrideAttrs (_: {
    postBuild = ''
      GOROOT="$(go env GOROOT)" ./go/bin/u-root \
        -uroot-source go/src/$goPackagePath \
        -uinitcmd=systemboot \
        core ./cmds/boot/{systemboot,localboot,fbnetboot}
    '';
    installPhase = ''
      mkdir -p $out
      cp /tmp/initramfs.*.cpio $out/initramfs.cpio
    '';
  });
in
(linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_0) src version modDirVersion kernelPatches extraMakeFlags;
  configfile =
    if
      stdenv.hostPlatform.system == "x86_64-linux" then ./linuxboot-x86_64.config
    else
      throw "unsupported architecture for linuxboot";
}).overrideAttrs (_: {
  preConfigure = ''
    cp ${initramfs}/initramfs.cpio /tmp/initramfs.cpio
  '';
})
