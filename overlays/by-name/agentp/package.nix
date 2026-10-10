{
  autoPatchelfHook,
  dbus,
  dpkg,
  fetchurl,
  libglvnd,
  libredirect,
  libuuid,
  libx11,
  libxcb,
  libxi,
  makeWrapper,
  stdenv,
  zlib,
}:

let
  # agentp hard-codes /var/agentp for everything (state, logs, unix sockets,
  # per-user lock files). Use libredirect to move those to standard
  # locations, which needs a few more wrappers than upstream has (most
  # importantly lstat, without which the daemon resets its config on every
  # start).
  libredirect' = libredirect.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [ ./libredirect-more-wrappers.patch ];
  });
in
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
    makeWrapper
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

  installPhase = ''
    runHook preInstall

    install -D -t $out/libexec/agentp usr/bin/agentp{,d}
    install -D -t $out/opt/agentp opt/agentp/agentp.ico

    # The daemon (run as root by systemd) keeps its state and logs in
    # /var/lib/agentp and /var/log/agentp.
    makeWrapper $out/libexec/agentp/agentpd $out/libexec/agentp/agentpd-daemon \
      --prefix LD_PRELOAD : ${libredirect'}/lib/libredirect.so \
      --set NIX_REDIRECTS /var/agentp/logs=/var/log/agentp:/var/agentp=/var/lib/agentp

    # Clients (UI and CLI, run as any user) talk to the daemon's sockets in
    # /var/lib/agentp, and keep their own logs and single-instance locks in
    # per-user directories instead of a world-writable /var/agentp.
    for bin in agentp agentpd; do
      makeWrapper $out/libexec/agentp/$bin $out/bin/$bin \
        --prefix LD_PRELOAD : ${libredirect'}/lib/libredirect.so \
        --run 'agentp_state=''${XDG_STATE_HOME:-$HOME/.local/state}/agentp' \
        --run 'mkdir -p "$agentp_state"' \
        --run 'export NIX_REDIRECTS="/var/agentp/logs=$agentp_state:/var/agentp/inst=''${XDG_RUNTIME_DIR:-/tmp}/agentp-inst:/var/agentp=/var/lib/agentp"'
    done

    install -D -m644 /dev/stdin $out/lib/systemd/system/agentpd.service <<EOF
    [Unit]
    Description=Portnox AgentP
    After=network.target

    [Service]
    Type=simple
    ExecStart=$out/libexec/agentp/agentpd-daemon -d
    Restart=on-failure
    RestartSec=5s
    StateDirectory=agentp
    LogsDirectory=agentp
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

    runHook postInstall
  '';

  meta.platforms = [ "x86_64-linux" ];
}
