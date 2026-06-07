{
  buildLuaPackage,
  fennel,
  fetchFromSourcehut,
  lua,
}:

let
  luaEnv = lua.withPackages (p: [ p.luasocket ]);
in
buildLuaPackage rec {
  pname = "shevek";
  version = builtins.substring 0 9 src.rev;

  src = fetchFromSourcehut {
    owner = "~technomancy";
    repo = "shevek";
    rev = "06b9a6b499b3b876937ead8e58028ed925a60611";
    hash = "sha256-1PxaPR0FUo9FH5gyZvOA8+u8+MYkdM5VyErwPetr9Y4=";
  };

  nativeBuildInputs = [ fennel ];

  buildPhase = ''
    runHook preBuild

    echo '#!${luaEnv}/bin/lua' >shevek.lua
    fennel --compile --require-as-include shevek.fnl >>shevek.lua

    runHook postBuild
  '';

  installPhase = ''
    runHook preInstall

    install -D shevek.lua $out/bin/shevek

    runHook postInstall
  '';

  meta = {
    description = "Simple nREPL client";
    maintainers = [ "jared@northwoodspace.io" ];
    mainProgram = "shevek";
  };
}
