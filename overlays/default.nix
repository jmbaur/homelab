inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    # needed by some stuff below
    inputs.auto-follow.overlays.default
    inputs.u-boot-nix.overlays.default
    # auto-added packages
    (
      _: prev:
      prev.lib.packagesFromDirectoryRecursive {
        inherit (prev) callPackage;
        directory = ./pkgs;
      }
    )
    # cross-compilation fixes
    (final: prev: {
      libfido2 = prev.libfido2.override {
        withPcsclite = final.stdenv.hostPlatform == final.stdenv.buildPlatform;
      };

      wpa_supplicant = prev.wpa_supplicant.override {
        withPcsclite = final.stdenv.hostPlatform == final.stdenv.buildPlatform;
      };

      perlPackages = prev.perlPackages.overrideScope (
        _: perlPackagesPrev: {
          NetDNS = perlPackagesPrev.NetDNS.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./perl-netdns-fix-cross.patch ];
          });
        }
      );

      userborn = prev.userborn.overrideAttrs (old: rec {
        patches = (old.patches or [ ]) ++ [ ./userborn-32bit.patch ];
        cargoDeps = final.rustPlatform.fetchCargoVendor ({
          inherit (old) src sourceRoot;
          inherit patches;
          hash = "sha256-0FAfAJT8//wto+/ZTeZp1Nu0Hn8Tt3Ewn3u6cO0dOCk=";
        });
      });
    })
    # all other packages
    (final: prev: {
      patchNameFromSubject =
        name:
        (final.lib.replaceStrings [ " " "[" "]" "," "/" ":" ] [ "-" "" "" "_" "_" "" ] name) + ".patch";

      nixVersions = prev.nixVersions.extend (
        _: nPrev: {
          nix_2_25_sysroot = nPrev.nix_2_25.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./nix-local-overlay-store-regex.patch ];
          });
        }
      );

      vimPlugins = prev.vimPlugins.extend (
        _: _: {
          bpftrace-vim = final.vimUtils.buildVimPlugin {
            name = "bpftrace.vim";
            src = final.fetchFromGitHub {
              owner = "mmarchini";
              repo = "bpftrace.vim";
              rev = "4c85f14c92eb75ddf68d27df8967aad399bdd18e";
              hash = "sha256-VLbvyH9+RWAcWisXEC3yKGSXPI72+bZbWyeMhgyuzPg=";
            };
          };
        }
      );

      gnome-console =
        (prev.gnome-console.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [ ./gnome-console-osc52.patch ];
        })).override
          {
            vte-gtk4 = final.vte-gtk4.overrideAttrs (old: {
              patches = (old.patches or [ ]) ++ [
                (final.fetchpatch {
                  name = "vte-osc52.patch";
                  url = "https://raw.githubusercontent.com/realh/roxterm/7706647daed0df4e95add44406e1ad48ce7954b7/vte-osc52.diff";
                  hash = "sha256-7ub973lHv7dL6za3M+kP8B7JO43CLKJZbZm/GreggJs=";
                })
              ];
            });
          };

      # Add support for colorized output.
      strace-with-colors = prev.strace.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (final.fetchpatch {
            url = "https://raw.githubusercontent.com/xfgusta/strace-with-colors/197c71f6f304f085e0c84151e6ccc6fcc2f29f7d/strace-with-colors.patch";
            hash = "sha256-gcQldGsRgvGnrDX0zqcLTpEpchNEbCUFdKyii0wetEI=";
          })
        ];
      });

      # Add support for PREF64 NDP option.
      tcpdump = prev.tcpdump.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (final.fetchpatch {
            url = "https://github.com/the-tcpdump-group/tcpdump/commit/d879d9349ab7b3dffc4797b6a8ece758e93636c1.patch";
            hash = "sha256-Z1gHBYNUMdIkNT+miI3Iis183yJvc29OLAvg6kkvDGY=";
          })
        ];
      });

      # Make dbus service file start the systemd service
      mako = prev.mako.overrideAttrs (old: {
        postInstall =
          (old.postInstall or "")
          # bash
          + ''
            substituteInPlace $out/share/dbus-1/services/fr.emersion.mako.service \
              --replace-fail "Exec=$out/bin/mako" "SystemdService=mako.service"
          '';
      });

      jared-neovim = prev.jared-neovim.override {
        neovim-unwrapped =
          inputs.neovim-nightly-overlay.packages.${final.stdenv.hostPlatform.system}.default.overrideAttrs
            (old: {
              patches = (old.patches or [ ]) ++ [
                # # TODO(jared): This allows neovim to detach from the
                # # controlling terminal, similar to tmux. This work is still WIP.
                # (final.fetchpatch {
                #   url = "https://github.com/neovim/neovim/commit/103b47d42afb217bd58d9add7750b81469f02177.patch";
                #   hash = "sha256-yn1fqhtf5jMJQp5o+QHU5dlm4PiSMh5cc9IZfJAHmW0=";
                # })
              ];
            });
      };
      jared-neovim-all-languages = final.jared-neovim.override { supportAllLanguages = true; };

      uboot-clearfog_uart = prev.uboot-clearfog.override {
        extraStructuredConfig = with final.lib.kernel; {
          MVEBU_SPL_BOOT_DEVICE_MMC = no;
          MVEBU_SPL_BOOT_DEVICE_UART = yes;
        };
      };

      marvellBinaries = final.fetchFromGitHub {
        owner = "MarvellEmbeddedProcessors";
        repo = "binaries-marvell";
        # branch: binaries-marvell-armada-SDK10.0.1.0
        rev = "b3d449e72196db5d48a2087c3df40b935834d304";
        hash = "sha256-m8NdvFSVo5+TPtpiGevyzXIMR1YcSQu5Xi5ewUX983Y=";
      };

      jmbaur-keybase-pgp-keys = final.fetchurl {
        url = "https://keybase.io/jaredbaur/pgp_keys.asc";
        sha256 = "sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
      };
    })
  ];
}
