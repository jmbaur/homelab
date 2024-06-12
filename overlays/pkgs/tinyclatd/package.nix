{
  buildPackages,
  dbus,
  lib,
  pkg-config,
  rustPlatform,
  makeWrapper,
  tayga,
}:

rustPlatform.buildRustPackage {
  pname = "tinyclatd";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.lock
      ./Cargo.toml
      ./build.rs
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  nativeBuildInputs = [
    pkg-config
    makeWrapper
  ];
  buildInputs = [ dbus ];

  env.SYSTEMD_DBUS_INTERFACE_DIR = "${buildPackages.systemd}/share/dbus-1/interfaces";

  postInstall = ''
    wrapProgram $out/bin/tinyclatd --prefix PATH : ${lib.makeBinPath [ tayga ]}
  '';

  meta = {
    description = "Minimal clat daemon that uses systemd-networkd and tayga";
    mainProgram = "tinyclatd";
  };
}
