{
  stdenv,
  fetchFromGitea,
  cmake,
  buildPackages,
  python3,
  picotool,
  gcc-arm-embedded,
}:

stdenv.mkDerivation {
  pname = "pico-serprog";
  version = "20230827";

  src = fetchFromGitea {
    domain = "codeberg.org";
    owner = "libreboot";
    repo = "pico-serprog";
    rev = "3ea792664ed29ca1ff3e2e78d1d16099684781bd";
    hash = "sha256-1Fo4g57vk4u5u1Q+Yrx/co8CE8/NxZDJdwIFQ+51f1Q=";
  };

  nativeBuildInputs = [
    gcc-arm-embedded
    picotool
    cmake
    python3
  ];

  cmakeFlags = [
    "-DPICO_SDK_PATH=${buildPackages.pico-sdk.override { withSubmodules = true; }}/lib/pico-sdk"
    "-DCMAKE_CXX_COMPILER=${buildPackages.gcc-arm-embedded}/bin/arm-none-eabi-g++"
    "-DCMAKE_C_COMPILER=${buildPackages.gcc-arm-embedded}/bin/arm-none-eabi-gcc"
  ];

  installPhase = ''
    runHook preInstall

    install -Dm644 -t $out pico_serprog.uf2

    runHook postInstall
  '';
}
