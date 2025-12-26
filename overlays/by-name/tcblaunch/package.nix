{
  lib,
  stdenv,
  fetchurl,
}:

assert (lib.assertMsg stdenv.hostPlatform.isAarch64 "tcblaunch only fetched for arm64 right now");
fetchurl {
  url = "https://msdl.microsoft.com/download/symbols/tcblaunch.exe/9351191Ef6000/tcblaunch.exe"; # TODO(jared): no idea if this is permalink-ish
  hash = "sha256-ltKyH7iemS6r2Do5ijn2a5S+MX1DefcxfEkkm5lrRQs=";
}
