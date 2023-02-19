{ buildGoModule, ... }:
buildGoModule {
  pname = "pomo";
  version = "0.0.1";
  src = ./.;
  vendorSha256 = null;
  ldflags = [ "-s" "-w" ];
}
