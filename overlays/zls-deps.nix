# generated by zon2nix (https://github.com/figsoda/zon2nix)

{ linkFarm, fetchzip }:

linkFarm "zig-packages" [
  {
    name = "12209cde192558f8b3dc098ac2330fc2a14fdd211c5433afd33085af75caa9183147";
    path = fetchzip {
      url = "https://github.com/ziglibs/known-folders/archive/0ad514dcfb7525e32ae349b9acc0a53976f3a9fa.tar.gz";
      hash = "sha256-X+XkFj56MkYxxN9LUisjnkfCxUfnbkzBWHy9pwg5M+g=";
    };
  }
  {
    name = "1220102cb2c669d82184fb1dc5380193d37d68b54e8d75b76b2d155b9af7d7e2e76d";
    path = fetchzip {
      url = "https://github.com/ziglibs/diffz/archive/ef45c00d655e5e40faf35afbbde81a1fa5ed7ffb.tar.gz";
      hash = "sha256-5/3W0Xt9RjsvCb8Q4cdaM8dkJP7CdFro14JJLCuqASo=";
    };
  }
]