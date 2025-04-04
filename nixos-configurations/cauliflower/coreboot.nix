{
  fetchgit,
  nss,
  openssl,
  pkg-config,
  pkgsBuildBuild,
  python3,
  stdenvNoCC,

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
  version = "24.12";

  src =
    (fetchgit {
      url = "https://github.com/coreboot/coreboot";
      rev = "24.12";
      hash = "sha256-mdxYxE3JiHFDaftNVckeQTVOlF8sWccm74MrpgWtXb4=";
      fetchSubmodules = true;
    }).overrideAttrs
      (_: {
        # https://github.com/nixos/nixpkgs/blob/4c62505847d88f16df11eff3c81bf9a453a4979e/pkgs/build-support/fetchgit/nix-prefetch-git#L328
        NIX_PREFETCH_GIT_CHECKOUT_HOOK = ''clean_git -C "$dir" submodule update --init --recursive --checkout -j ''${NIX_BUILD_CORES:-1} --progress'';
      });

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
