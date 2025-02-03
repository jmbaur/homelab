{
  lib,
  libgit2,
  openssl,
  pkg-config,
  rustPlatform,
}:

let
  commands = [
    "help"
    "create"
    "list"
  ];
in
rustPlatform.buildRustPackage rec {
  pname = "homelab-git-shell-commands";
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

  nativeBuildInputs = [ pkg-config ];
  buildInputs = [
    libgit2
    openssl
  ];

  postInstall = ''
    mkdir -p $out/git-shell-commands
    for command in ${toString commands}; do
      ln -sf $out/bin/${pname} $out/git-shell-commands/$command
    done
  '';

  meta.description = "Program implementing ~/git-shell-commands";
}
