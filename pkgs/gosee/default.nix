{ pkgs ? import <nixpkgs> { } }:
pkgs.callPackage
  (builtins.fetchTarball {
    url = "https://github.com/jmbaur/gosee/archive/ca8c5914ff8db9993a68663447d46bffd364d99c.tar.gz";
    sha256 = "1yiw17sfmlhjwd18r5iaklhbzsicfd62w015znihplmlk2nqx75i";
  })
{ }
