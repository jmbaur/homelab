{ callPackage, fetchFromGitHub }:
callPackage
  (fetchFromGitHub {
    owner = "jmbaur";
    repo = "gosee";
    rev = "ca8c5914ff8db9993a68663447d46bffd364d99c";
    sha256 = "1yiw17sfmlhjwd18r5iaklhbzsicfd62w015znihplmlk2nqx75i";
  })
{ }
