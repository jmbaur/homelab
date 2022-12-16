{ fetchurl }: [
  {
    name = "gmp-6.2.1.tar.xz";
    archive = fetchurl {
      sha256 = "1wml97fdmpcynsbw9yl77rj29qibfp652d0w3222zlfx5j8jjj7x";
      url = "mirror://gnu/gmp/gmp-6.2.1.tar.xz";
    };
  }
  {
    name = "mpfr-4.1.0.tar.xz";
    archive = fetchurl {
      sha256 = "0zwaanakrqjf84lfr5hfsdr7hncwv9wj0mchlr7cmxigfgqs760c";
      url = "mirror://gnu/mpfr/mpfr-4.1.0.tar.xz";
    };
  }
  {
    name = "mpc-1.2.1.tar.gz";
    archive = fetchurl {
      sha256 = "0n846hqfqvmsmim7qdlms0qr86f1hck19p12nq3g3z2x74n3sl0p";
      url = "mirror://gnu/mpc/mpc-1.2.1.tar.gz";
    };
  }
  {
    name = "gcc-11.2.0.tar.xz";
    archive = fetchurl {
      sha256 = "12zs6vd2rapp42x154m479hg3h3lsafn3xhg06hp5hsldd9xr3nh";
      url = "mirror://gnu/gcc/gcc-11.2.0/gcc-11.2.0.tar.xz";
    };
  }
  {
    name = "binutils-2.37.tar.xz";
    archive = fetchurl {
      sha256 = "0b53hhgfnafw27y0c3nbmlfidny2cc5km29pnfffd8r0y0j9f3c2";
      url = "mirror://gnu/binutils/binutils-2.37.tar.xz";
    };
  }
  {
    name = "acpica-unix2-20220331.tar.gz";
    archive = fetchurl {
      sha256 = "0yjcl00nnnlw01sz6a1i5d3v75gr17mkbxkxfx2v344al33abk8w";
      url = "https://acpica.org/sites/acpica/files/acpica-unix2-20220331.tar.gz";
    };
  }
  {
    name = "llvm-15.0.0.src.tar.xz";
    archive = fetchurl {
      sha256 = "1l0h7kr96biwaxyxsg6i2fm7z313jzc471cp5cw75gpkcnv3bl2c";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/llvm-15.0.0.src.tar.xz";
    };
  }
  {
    name = "clang-15.0.0.src.tar.xz";
    archive = fetchurl {
      sha256 = "0rgzf2gjra32m4gr46633jxis4wgkb44zis2hihq5y62lsp8k5nj";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/clang-15.0.0.src.tar.xz";
    };
  }
  {
    name = "cmake-15.0.0.src.tar.xz";
    archive = fetchurl {
      sha256 = "13wfz362g6js8d67wbx050ga70y2m2vb2g94i32jz38gs339cc1a";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/cmake-15.0.0.src.tar.xz";
    };
  }
  {
    name = "compiler-rt-15.0.0.src.tar.xz";
    archive = fetchurl {
      sha256 = "0ggalalb0jafvfv7mfk4mdwh23ihxvcqakzz9b7jxqyr0w2cl4ci";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/compiler-rt-15.0.0.src.tar.xz";
    };
  }
  {
    name = "clang-tools-extra-15.0.0.src.tar.xz";
    archive = fetchurl {
      sha256 = "0i097y9wwsccqmkhvhha1qhr6wffhqxmxrhy11v77l4kvqnmp450";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.0/clang-tools-extra-15.0.0.src.tar.xz";
    };
  }
  {
    name = "cmake-3.24.2.tar.gz";
    archive = fetchurl {
      sha256 = "1ny8y2dzc6fww9gzb1ml0vjpx4kclphjihkxagxigprxdzq2140d";
      url = "https://cmake.org/files/v3.24/cmake-3.24.2.tar.gz";
    };
  }
  {
    name = "nasm-2.15.05.tar.bz2";
    archive = fetchurl {
      sha256 = "1l1gxs5ncdbgz91lsl4y7w5aapask3w02q9inayb2m5bwlwq6jrw";
      url = "https://www.nasm.us/pub/nasm/releasebuilds/2.15.05/nasm-2.15.05.tar.bz2";
    };
  }
]
