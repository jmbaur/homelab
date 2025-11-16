{
  fetchgit,
  nss,
  openssl,
  pkg-config,
  pkgsBuildBuild,
  python3,
  stdenvNoCC,
}:
{
  kconfig ? "",
}:

let
  toolchain =
    pkgsBuildBuild.coreboot-toolchain.${
      {
        i386 = "i386";
        x86_64 = "i386";
        arm64 = "aarch64";
        arm = "arm";
        riscv = "riscv";
        powerpc = "ppc64";
      }
      .${stdenvNoCC.hostPlatform.linuxArch}
    }.override
      { withAda = stdenvNoCC.hostPlatform.isx86_64; };
in
stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "coreboot";
  version = "25.09";

  src = fetchgit {
    url = "https://github.com/coreboot/coreboot";
    rev = finalAttrs.version;
    hash = "sha256-ItQVCDC/MiF5rgecmxeR000lqTQy1VCSSILl1z4bJmM=";
    fetchSubmodules = true;
  };

  depsBuildBuild = [
    pkgsBuildBuild.stdenv.cc
    pkg-config
    openssl
    nss
    python3
  ];

  strictDeps = true;
  enableParallelBuilding = true;

  inherit kconfig;
  passAsFile = [ "kconfig" ];

  makeFlags = [
    "BUILD_TIMELESS=1"
    "KERNELVERSION=${finalAttrs.version}"
    "UPDATED_SUBMODULES=1"
    "XGCCPATH=${toolchain}/bin/"
  ];

  postPatch = ''
    patchShebangs util 3rdparty/vboot/scripts
  '';

  configurePhase = ''
    runHook preConfigure

    cat $kconfigPath > .config
    make -j$NIX_BUILD_CORES olddefconfig

    runHook postConfigure
  '';

  installPhase = ''
    runHook preInstall

    install -Dm0444 --target-directory=$out build/coreboot.rom .config

    runHook postInstall
  '';
})
