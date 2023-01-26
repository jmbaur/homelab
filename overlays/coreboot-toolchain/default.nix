{ stdenv
, stdenvNoCC
, lib
, bison
, buildPackages
, callPackage
, curl
, fetchgit
, flex
, getopt
, git
, gnat11
, perl
, zlib
, withAda ? false
}:
let
  crossgcc_arch = builtins.getAttr stdenv.hostPlatform.system {
    x86_64-linux = "i386";
    aarch64-linux = "aarch64";
    armv7l-linux = "arm";
    riscv64-linux = "riscv";
    powerpc64-linux = "ppc64";
  };
in
stdenvNoCC.mkDerivation rec {
  pname = "coreboot-toolchain-${crossgcc_arch}";
  version = "4.19";

  src = fetchgit {
    url = "https://review.coreboot.org/coreboot";
    rev = version;
    sha256 = "sha256-pGS+bfX2k/ot7sHL9aiaQpA0wtbHHZEObJ/h2JGF5/4=";
    fetchSubmodules = false;
    leaveDotGit = true;
    postFetch = ''
      PATH=${lib.makeBinPath [ getopt ]}:$PATH ${stdenv.shell} $out/util/crossgcc/buildgcc -W > $out/.crossgcc_version
      rm -rf $out/.git
    '';
    allowedRequisites = [ ];
  };

  depsBuildBuild = [ (if withAda then buildPackages.gnat11 else buildPackages.stdenv.cc) ];
  nativeBuildInputs = [ flex bison curl git perl ];
  buildInputs = [ zlib ];

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
    make crossgcc-${crossgcc_arch} CPUS=$NIX_BUILD_CORES DEST=$out
  '';

  meta = with lib; {
    homepage = "https://www.coreboot.org";
    description = "coreboot toolchain for ${crossgcc_arch} targets";
    license = with licenses; [ bsd2 bsd3 gpl2 lgpl2Plus gpl3Plus ];
    maintainers = with maintainers; [ felixsinger ];
    platforms = platforms.linux;
  };
}
