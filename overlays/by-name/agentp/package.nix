{
  autoPatchelfHook,
  dpkg,
  fetchurl,
  libgcc,
  libglvnd,
  libuuid,
  libx11,
  libxcb,
  libxi,
  stdenv,
  zlib,
}:

stdenv.mkDerivation {
  pname = "agentp";
  version = "1.1.64";

  src = fetchurl {
    url = "https://files.catbox.moe/asc5zv.deb";
    hash = "sha256-4oWWRMs/NRXMHoDoULDJ7Kqr6ASpgvcShtmF+K59AJI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  # TODO(jared): this shouldn't be needed
  autoPatchelfIgnoreMissingDeps = true;

  runtimeDependencies = [
    libgcc
    libglvnd
    libuuid.lib
    libx11
    libxcb
    libxi
    zlib
  ];

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p $out/share $out/lib $out/opt
    install -D -t $out/bin usr/bin/agentp{,d}
    cp -r usr/share/applications $out/share
    cp -r lib/systemd $out/lib
    cp -r opt/agentp $out/opt
    substituteInPlace $out/lib/systemd/system/agentpd.service \
      --replace-fail /usr/bin ${placeholder "out"}/bin
    substituteInPlace $out/share/applications/agentp.desktop \
      --replace-fail /opt ${placeholder "out"}/opt \
      --replace-fail /usr/bin ${placeholder "out"}/bin
    substituteInPlace $out/share/applications/agentp-handler.desktop \
      --replace-fail /opt ${placeholder "out"}/opt \
      --replace-fail /usr/bin ${placeholder "out"}/bin
    runHook postInstall
  '';
}
