{ buildGoModule, pkgconfig, libgit2, ... }:
buildGoModule rec {
  name = "git-shell-commands";
  src = ./.;
  vendorSha256 = "sha256-aO5JldXyLRqkUoSDmjgg/NLMYay5bucXbeNqW4h1e5U=";
  nativeBuildInputs = [ pkgconfig ];
  buildInputs = [ libgit2 ];
  ldflags = [ "-X main.progname=${name}" "-s" "-w" ];
  postInstall = ''
    for cmd in "help" "list" "create" "delete"; do
      ln -s $out/bin/git-shell-commands $out/$cmd
    done
  '';
}
