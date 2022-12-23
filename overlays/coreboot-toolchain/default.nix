{ stdenv
, bison
, buildPackages
, callPackage
, curl
, fetchgit
, flex
, getopt
, git
, gnat11
, lib
, perl
, stdenvNoCC
, zlib
, withAda ? false
}:
let
  arch =
    if
      stdenv.hostPlatform.system == "x86_64-linux" then "i386"
    else if
      stdenv.hostPlatform.system == "aarch64-linux" then "aarch64"
    else throw "unsupported architecture";
in
stdenvNoCC.mkDerivation rec {
  pname = "coreboot-toolchain";
  version = "4.18";

  src = fetchgit {
    url = "https://review.coreboot.org/coreboot";
    rev = version;
    sha256 = "sha256-vilaYPNW1Ni8z8k1Bxu4ZvbSla/q3xGwS0fEEWxmux4=";
    fetchSubmodules = false;
    leaveDotGit = true;
    postFetch = ''
      PATH=${lib.makeBinPath [ getopt ]}:$PATH ${stdenv.shell} $out/util/crossgcc/buildgcc -W > $out/.crossgcc_version
      rm -rf $out/.git
    '';
    allowedRequisites = [ ];
  };

  depsBuildBuild = [ (if withAda then buildPackages.gnat11 else buildPackages.stdenv.cc) ];
  nativeBuildInputs = [ bison curl git perl ];
  buildInputs = [ flex zlib ];

  enableParallelBuilding = true;
  dontConfigure = true;
  dontInstall = true;

  postPatch = ''
    patchShebangs util/crossgcc/buildgcc

    mkdir -p util/crossgcc/tarballs

    ${lib.concatMapStringsSep "\n" (
      file: "ln -s ${file.archive} util/crossgcc/tarballs/${file.name}"
      ) (callPackage ./sources.nix { })
    }

    patchShebangs util/genbuild_h/genbuild_h.sh
  '';

  buildPhase = ''
    export CROSSGCC_VERSION=$(cat .crossgcc_version)
    make crossgcc-${arch} CPUS=$NIX_BUILD_CORES DEST=$out
  '';

  meta = with lib; {
    homepage = "https://www.coreboot.org";
    description = "coreboot toolchain";
    license = with licenses; [ bsd2 bsd3 gpl2 lgpl2Plus gpl3Plus ];
    maintainers = with maintainers; [ felixsinger ];
    platforms = platforms.linux;
  };
}
