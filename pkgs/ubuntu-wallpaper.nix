{ stdenvNoCC, dpkg, fetchurl }:
stdenvNoCC.mkDerivation {
  name = "ubuntu-wallpapers";
  nativeBuildInputs = [ dpkg ];
  unpackCmd = "mkdir root ; dpkg-deb -x $curSrc root";
  src = fetchurl {
    url = "mirror://ubuntu/pool/main/u/ubuntu-wallpapers/ubuntu-wallpapers_22.04.4-0ubuntu1_all.deb";
    sha256 = "sha256-YoEeoVzo/9lOWhsfDwJUQqyHZAzoVkvf7w9cQIa4dVo=";
  };
  installPhase = ''
    mkdir -p $out
    cp usr/share/backgrounds/warty-final-ubuntu.png $out/jammy-jellyfish.png
  '';
}
