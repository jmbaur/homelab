{ lib, stdenv, linuxKernel, fetchpatch, ... }:
let
  base = linuxKernel.kernels.linux_testing;
in
(linuxKernel.manualConfig {
  inherit lib stdenv;
  inherit (base) src version modDirVersion extraMakeFlags;
  kernelPatches = base.kernelPatches ++ [
    rec {
      name = "mt8192-asurada-regulators";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/lkml/20221102190611.283546-2-nfraprado@collabora.com/raw";
        sha256 = "sha256-SbF1l8QDNSxkh3FwN0AE4adx7Dxzddie3FFFD+YANT0=";
      };
    }
    rec {
      name = "mt8192-asurada-backlight";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/lkml/20221102190611.283546-3-nfraprado@collabora.com/raw";
        sha256 = "sha256-vOgc1JzWuMOC4y/Oa9FOSBa6LzRtVVnTBT91R+qgOKU=";
      };
    }
    rec {
      name = "mt8192-asurada-audio.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/lkml/20221102190611.283546-4-nfraprado@collabora.com/raw";
        sha256 = "sha256-cDnsShBTUPpSi4tNjdN+98bZ1ILDyFF6x9DyoqJrL5A=";
      };
    }
    rec {
      name = "mt8192-asurada-spherion-audio.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/lkml/20221102190611.283546-5-nfraprado@collabora.com/raw";
        sha256 = "sha256-82rHlVxYxN0Bgd6g+Rb/paUIIrXT3nMyuj8oP3l4aUk=";
      };
    }
    rec {
      name = "mt8192-asurada-i2c-mmc-aliases.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://lore.kernel.org/lkml/20221102190611.283546-6-nfraprado@collabora.com/raw";
        sha256 = "sha256-xgP2nyGmfej35kclKffDhL3oklN6+dMnIQW12uei03o=";
      };
    }
    rec {
      name = "mt8192-gpu.patch";
      patch = fetchpatch {
        inherit name;
        url = "https://gitlab.freedesktop.org/gfx-ci/linux/-/commit/3842f3a80e65.patch";
        sha256 = "sha256-TrrS7pYhKL2Cs0kFPEuOUQvTMgIvkd2j5f4uWJJuMH4=";
      };
    }
  ];
  configfile = ./mediatek.config;
  # Prevent nixos from complaining about bad config values. The config values
  # are fine, they just aren't defined in nix code.
  allowImportFromDerivation = true;
}
).overrideAttrs
  (old: {
    # TODO(jared): find a better way to set the config to allow for installing DTBs
    passthru = old.passthru // {
      config = old.passthru.config // {
        DTB = stdenv.hostPlatform.system != "x86_64-linux";
      };
    };
  })
