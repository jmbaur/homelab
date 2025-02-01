{
  lib,
  rustPlatform,
}:

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

  postInstall = ''
    mkdir -p $out/git-shell-commands
    for command in foo bar; do
      ln -sf $out/bin/${pname} $out/git-shell-commands/$command
    done
  '';

  meta.description = "Program implementing ~/git-shell-commands";
}
