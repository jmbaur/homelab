{
  buildLuaPackage,
  fennel,
  lib,
  lua,
}:

buildLuaPackage {
  pname = "swaybar";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Makefile
      ./swaybar.fnl
    ];
  };

  makeFlags = [
    "LUA=${
      lib.getExe (
        lua.withPackages (p: [
          p.cqueues
          p.dkjson
          # p.jeejah
          p.ldbus
        ])
      )
    }"
  ];

  nativeBuildInputs = [ fennel ];
  propagatedBuildInputs = [ ];

  meta.mainProgram = "lua-swaybar";
}
