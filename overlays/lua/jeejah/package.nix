{
  buildLuaPackage,
  fetchFromSourcehut,
  fetchurl,
  lua,
  luasocket,
  pkgsBuildBuild,
}:

let
  fennelSrc = fetchurl {
    url = "https://fennel-lang.org/downloads/fennel-1.6.1.lua";
    hash = "sha256-w9RWAgQefY74ohJWNXPfBAxIqFxkiin7RZfr7UvDjsI=";
  };
in
buildLuaPackage rec {
  pname = "jeejah";
  version = builtins.substring 0 9 src.rev;

  src = fetchFromSourcehut {
    owner = "~technomancy";
    repo = "jeejah";
    rev = "6df08cdf96e76b378e69304c432d889fe6f544ba";
    hash = "sha256-WDniR7fz8066ybfMhg/hPY+qwGc2J97WGHhK2vn9n5U=";
  };

  patches = [ ./allow-custom-address.patch ];

  depsBuildBuild = [ pkgsBuildBuild.luaPackages.fennel ];

  propagatedBuildInputs = [ luasocket ];

  buildPhase = ''
    runHook preBuild

    fennel --compile --require-as-include jeejah.fnl >jeejah.lua
    install -Dm0644 --target-directory=$out/share/lua/${lua.luaversion} jeejah.lua bencode.lua
    install -Dm0644 ${fennelSrc} $out/share/lua/${lua.luaversion}/fennel.lua

    runHook postBuild
  '';

  dontInstall = true;
}
