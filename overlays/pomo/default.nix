{ buildGoModule, ... }:
buildGoModule {
  pname = "pomo";
  version = "0.0.1";
  src = ./.;
  vendorHash = null;
  ldflags = [ "-s" "-w" ];
}
