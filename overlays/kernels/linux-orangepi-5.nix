{ lib, stdenv, linuxKernel, fetchFromGitHub, ... }:
let
  armbian = fetchFromGitHub {
    owner = "armbian";
    repo = "build";
    rev = "79019296d81b8b4686a817019bd8ce32b8d4e462";
    sha256 = "sha256-hTjWQVlNrEqcsViH4BWwGIbuT8BUcWDGudf0u6h6TCM=";
  };

  patchDir = "${armbian}/patch/kernel/rockchip-rk3588-legacy";
  patchPath = file: "${patchDir}/${file}";
  kernelPatches = builtins.map
    (x: { name = x; patch = patchPath x; })
    (builtins.attrNames (builtins.readDir patchDir));
in
linuxKernel.manualConfig {
  inherit lib stdenv kernelPatches;

  version = "5.10.110-rockchip-rk3588";
  modDirVersion = "5.10.110";

  src = fetchFromGitHub {
    owner = "radxa";
    repo = "kernel";
    rev = "5ed081f51946a89539a5d6e1d8ef2f73a3ef295c";
    hash = "sha256-LMOWcPl3nBA1b68zwOAXtH/lhzhDGDTvQlM4sA9qOFs=";
  };

  configfile = "${armbian}/config/kernel/linux-rockchip-rk3588-legacy.config";

  allowImportFromDerivation = true;

  extraMeta.branch = "5.10";
}
