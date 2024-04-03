{ lib, buildUBoot }:
buildUBoot {
  defconfig = "tools-only_defconfig";
  installDir = "$out/bin";
  hardeningDisable = [ ];
  dontStrip = false;
  extraMeta.platforms = lib.platforms.linux;
  extraMakeFlags = [
    "HOST_TOOLS_ALL=y"
    "CROSS_BUILD_TOOLS=1"
    "NO_SDL=1"
    "envtools"
  ];

  outputs = [
    "out"
    "man"
  ];

  postInstall = ''
    installManPage doc/*.1
    ln -s $out/bin/fw_printenv $out/bin/fw_setenv
  '';

  filesToInstall = [ "tools/env/fw_printenv" ];
}
