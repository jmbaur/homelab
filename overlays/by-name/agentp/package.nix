{
  autoPatchelfHook,
  dbus,
  dpkg,
  fetchurl,
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

  # NOTE: Portnox doesn't offer versioned download URLs, this always serves the
  # latest release, so the hash will break when a new version is published.
  src = fetchurl {
    name = "PortnoxAgentP.deb";
    url = "https://clear.portnox.com/enduser/DownloadAgentPForOsAndPackageType?osType=5&packageType=Deb&architecture=X64";
    hash = "sha256-4oWWRMs/NRXMHoDoULDJ7Kqr6ASpgvcShtmF+K59AJI=";
  };

  nativeBuildInputs = [
    autoPatchelfHook
    dpkg
  ];

  buildInputs = [
    stdenv.cc.cc.lib
    libglvnd
    libuuid
    libx11
    libxcb
    libxi
    zlib
  ];

  # dlopen'ed by the UI for its tray icon
  runtimeDependencies = [ dbus.lib ];

  dontConfigure = true;
  dontBuild = true;

  # agentp hard-codes /var/agentp for everything (state, logs, unix sockets,
  # certs, per-user lock files), and writes that path into the NetworkManager
  # profiles it generates, so it's left there.
  installPhase = ''
    runHook preInstall

    install -D -t $out/bin usr/bin/agentp{,d}
    install -D -t $out/opt/agentp opt/agentp/agentp.ico

    install -D -m644 /dev/stdin $out/lib/systemd/system/agentpd.service <<EOF
    [Unit]
    Description=Portnox AgentP
    After=network.target

    [Service]
    Type=simple
    ExecStart=$out/bin/agentpd -d
    Restart=on-failure
    RestartSec=5s
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target
    EOF

    mkdir -p $out/share/applications
    for desktop in agentp agentp-handler; do
      substitute usr/share/applications/$desktop.desktop $out/share/applications/$desktop.desktop \
        --replace-fail /opt $out/opt \
        --replace-fail /usr/bin $out/bin
    done

    # Upstream's postinst copies a variant of this to the installing user's
    # ~/.config/autostart.
    install -D -m644 -t $out/etc/xdg/autostart $out/share/applications/agentp.desktop

    runHook postInstall
  '';

  meta.platforms = [ "x86_64-linux" ];
}
