{ fetchurl }: [
  {
    name = "gmp-6.2.1.tar.xz";
    archive = fetchurl {
      sha256 = "1wml97fdmpcynsbw9yl77rj29qibfp652d0w3222zlfx5j8jjj7x";
      url = "mirror://gnu/gmp/gmp-6.2.1.tar.xz";
    };
  }
  {
    name = "mpfr-4.1.1.tar.xz";
    archive = fetchurl {
      sha256 = "0gf3ibi7kzz39zj72qc9r607clyhm80gs8wbp71zzfkxasyrblgz";
      url = "mirror://gnu/mpfr/mpfr-4.1.1.tar.xz";
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
    name = "R10_20_22.tar.gz";
    archive = fetchurl {
      sha256 = "11iv3jrz27g7bv7ffyxsrgm4cq60cld2gkkl008p3lcwfyqpx88s";
      url = "https://github.com/acpica/acpica/archive/refs/tags//R10_20_22.tar.gz";
    };
  }
  {
    name = "llvm-15.0.6.src.tar.xz";
    archive = fetchurl {
      sha256 = "1qv7d7rbgjbsxywlyrbh4p5bwxyxp9gqqsl4ac1jwzpj06a1jchb";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/llvm-15.0.6.src.tar.xz";
    };
  }
  {
    name = "clang-15.0.6.src.tar.xz";
    archive = fetchurl {
      sha256 = "0csjjbyafjjcyjidcbwq9q6hqnqp3rw7prj2zrwzkd7ijphrl48h";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/clang-15.0.6.src.tar.xz";
    };
  }
  {
    name = "cmake-15.0.6.src.tar.xz";
    archive = fetchurl {
      sha256 = "11jcrcnqip2lz9bm0qhrb594bymm971ln114aari52wvpbmaw4vn";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/cmake-15.0.6.src.tar.xz";
    };
  }
  {
    name = "compiler-rt-15.0.6.src.tar.xz";
    archive = fetchurl {
      sha256 = "1g0zm390mp3j0j06dklzs672l2qyalnxyyifv6ng6bj009dmnvxl";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/compiler-rt-15.0.6.src.tar.xz";
    };
  }
  {
    name = "clang-tools-extra-15.0.6.src.tar.xz";
    archive = fetchurl {
      sha256 = "099v2yqg11h0h8qqddzkny6b77pafcr7vy5ksc33kqggji173ccj";
      url = "https://github.com/llvm/llvm-project/releases/download/llvmorg-15.0.6/clang-tools-extra-15.0.6.src.tar.xz";
    };
  }
  {
    name = "cmake-3.25.0.tar.gz";
    archive = fetchurl {
      sha256 = "0j6xii9x0d3zmsjr97cb2y3w8w0gaqv0fnkg5saa0pam87sn6r1h";
      url = "https://cmake.org/files/v3.25/cmake-3.25.0.tar.gz";
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
