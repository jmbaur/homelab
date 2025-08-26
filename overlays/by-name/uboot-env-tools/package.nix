{
  lib,
  stdenv,
  ubootTools,
}:

stdenv.mkDerivation (_: {
  pname = "uboot-env-tools";
  inherit (ubootTools)
    depsBuildBuild
    nativeBuildInputs
    src
    version
    ;

  configurePhase = ''
    runHook preConfigure

    make -j$NIX_BUILD_CORES tools-only_defconfig

    runHook postConfigure
  '';

  makeFlags = [
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "envtools"
  ];

  installPhase = ''
    runHook preInstall

    install -Dt $out/bin tools/env/fw_printenv
    ln -sf $out/bin/{fw_printenv,fw_setenv}

    runHook postInstall
  '';

  meta.platforms = lib.platforms.linux;
})
