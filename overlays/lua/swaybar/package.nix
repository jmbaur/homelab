{
  buildLuaPackage,
  cqueues,
  dkjson,
  fennel,
  jeejah,
  ldbus,
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
        lua.withPackages (_: [
          cqueues
          dkjson
          jeejah
          ldbus
        ])
      )
    }"
  ];

  nativeBuildInputs = [ fennel ];
  propagatedBuildInputs = [ ];

  meta.mainProgram = "lua-swaybar";
}
