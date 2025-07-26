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
  version = "R139";

  src = fetchFromGitiles {
    url = "https://chromium.googlesource.com/chromiumos/platform/ec";
    rev = "24fb02dc0b0e62f0e40d5624aaed2bfa3b81b7f1"; # release-R139-16328.B-main
    hash = "sha256-3uG7QZsMROD6nf6++mrHM2O7ekhY9X4B7wTX8Es69/I=";
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
