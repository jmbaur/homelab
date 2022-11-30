{ buildGoModule, ... }:
buildGoModule {
  pname = "pomo";
  version = "0.0.1";
  src = ./.;
  vendorSha256 = "sha256-pQpattmS9VmO3ZIQUFn66az8GSmB4IvYhTTCFn6SUmo=";
}
