{
  lib,
  rustPlatform,
}:

rustPlatform.buildRustPackage {
  pname = "homelab-backup-recv";
  version = "0.1.0";

  src = lib.fileset.toSource {
    root = ./.;
    fileset = lib.fileset.unions [
      ./Cargo.lock
      ./Cargo.toml
      ./src
    ];
  };

  cargoLock.lockFile = ./Cargo.lock;

  meta = {
    description = "Program to receive btrfs snapshots where the connecting IPv6 address identifies the sender (e.g. in the yygdrasil network)";
    mainProgram = "homelab-backup-recv";
  };
}
