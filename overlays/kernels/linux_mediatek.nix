{ lib, stdenv, linuxKernel, ... }:
(linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (linuxKernel.kernels.linux_6_1) src version modDirVersion kernelPatches extraMakeFlags;
  configfile = ./mediatek.config;
  # Prevent nixos from complaining about bad config values. The config values
  # are fine, they just aren't defined in nix code.
  allowImportFromDerivation = true;
}).overrideAttrs (old: {
  # TODO(jared): find a better way to set the config to allow for installing DTBs
  passthru = old.passthru // {
    config = old.passthru.config // {
      DTB = stdenv.hostPlatform.system != "x86_64-linux";
    };
  };
})
