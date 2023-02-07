{ flashrom, fetchFromGitHub, ... }:
flashrom.overrideAttrs (_: rec {
  pname = "flashrom-dasharo";
  version = "dasharo-v1.2.2";

  src = fetchFromGitHub {
    owner = "dasharo";
    repo = "flashrom";
    rev = version;
    sha256 = "sha256-VOCO8F62K14/E1Yp6tlEsJMnh++2qfLR28uQGiJFmW0=";
  };

  # util/z60_flashrom.rules was moved to util/flashrom_udev.rules
  postPatch = ''
    substituteInPlace util/flashrom_udev.rules --replace "plugdev" "flashrom"
  '';
  postInstall = ''
    install -Dm644 util/flashrom_udev.rules $out/lib/udev/rules.d/flashrom.rules
  '';
})
