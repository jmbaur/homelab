{
  buildPackages,
  dbus,
  lib,
  pkg-config,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "tinybar";
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

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [ dbus ];

  env = {
    SYSTEMD_DBUS_INTERFACE_DIR = "${buildPackages.systemd}/share/dbus-1/interfaces";
    UPOWER_DBUS_INTERFACE_DIR = "${buildPackages.upower}/share/dbus-1/interfaces";
  };

  meta = {
    description = "Minimal configuration-free i3/sway compatible statusbar";
    mainProgram = "tinybar";
  };
}
