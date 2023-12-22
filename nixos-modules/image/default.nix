{ modulesPath, ... }: {
  imports = [
    "${modulesPath}/image/repart.nix" # TODO(jared): why isn't this included in nixpkgs?
    ./immutable.nix
  ];
}
