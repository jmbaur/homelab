{
  board ? throw "no board provided",
  fetchFromGitiles,
  gcc-arm-embedded,
  libftdi,
  libusb1,
  ncurses,
  net-tools,
  pkg-config,
  pkgsBuildBuild,
  stdenv,
  vboot_reference,
}:

stdenv.mkDerivation {
  pname = "cros-ec-${board}";
  version = "R154";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/platform/ec";
    rev = "ea43872eaadb3ab8d044fa6dbcc9a6b4ef72efc2"; # release-R154-16805.B-ec-legacy
    hash = "sha256-YOnrhmjfN11fmgHRjLm4Jlg+XOhFzu4yXcY2PIkm3f8=";
  };

  postPatch = ''
    patchShebangs util
  '';

  depsBuildBuild = [
    net-tools
    gcc-arm-embedded
    libftdi
    libusb1
    ncurses
    pkg-config
    pkgsBuildBuild.stdenv.cc
    vboot_reference
  ];

  env.NIX_CFLAGS_COMPILE = "-Wno-address -Wno-stringop-truncation";

  strictDeps = true;
  enableParallelBuilding = true;

  makeFlags = [
    "CROSS_COMPILE=arm-none-eabi-"
    "BOARD=${board}"
    "out=out"
    "out/ec.bin"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm0644 -t $out out/ec.bin

    runHook postInstall
  '';
}
