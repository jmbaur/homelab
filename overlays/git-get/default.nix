{ buildGoModule, installShellFiles, ... }:
buildGoModule {
  pname = "git-get";
  version = "0.1.0";
  src = ./.;
  nativeBuildInputs = [ installShellFiles ];
  vendorSha256 = "sha256-Z0H01Ts6RlBFwKgx+9YYAd9kT4BkCBL1mvJsRf2ci5I=";
  ldflags = [ "-s" "-w" ];
  postInstall = ''
    installShellCompletion --bash --name git-get.bash share/completions.bash
  '';
}
