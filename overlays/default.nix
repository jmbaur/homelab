inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    # needed by some stuff below
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
    })
    # all other packages
    (final: prev: {
      nixVersions = prev.nixVersions.extend (
        _: nPrev: {
          nix_2_25_sysroot = nPrev.nix_2_25.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./nix-local-overlay-store-regex.patch ];
          });
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

      # Enable experimental multithreading support in mkfs.erofs
      erofs-utils = prev.erofs-utils.overrideAttrs (old: {
        configureFlags = (old.configureFlags or [ ]) ++ [ "--enable-multithreading" ];
      });

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
          + ''
            substituteInPlace $out/share/dbus-1/services/fr.emersion.mako.service \
              --replace-fail "Exec=$out/bin/mako" "SystemdService=mako.service"
          '';
      });

      git-shell-commands = prev.callPackage ./git-shell-commands {
        libgit2 = prev.libgit2.overrideAttrs (_: rec {
          version = "1.5.2";
          src = final.fetchFromGitHub {
            owner = "libgit2";
            repo = "libgit2";
            rev = "v${version}";
            hash = "sha256-zZetfuiSpiO0rRtZjBFOAqbdi+sCwl120utnXLtqMm0=";
          };
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

      mvDdrMarvell = final.applyPatches rec {
        src = final.fetchgit {
          url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
          rev = "bfcf62051be835f725005bb5137928f7c27b792e";
          hash = "sha256-a6Hjx4/4uxQqNZRRa331B7aOtsyaUNhGh3izOSBrL3c=";
        };
        patches = [
          (final.substituteAll {
            src = ./mv-ddr-marvell-version.patch;
            shortRev = builtins.substring 0 7 src.rev;
          })
        ];
      };

      cn9130CfProSdFirmware = prev.callPackage ./cn913x/firmware.nix { spi = false; };
      cn9130CfProSpiFirmware = prev.callPackage ./cn913x/firmware.nix { spi = true; };

      jmbaur-keybase-pgp-keys = final.fetchurl {
        url = " https://keybase.io/jaredbaur/pgp_keys.asc ";
        sha256 = " sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
      };

      extractLinuxFirmware =
        name: paths:
        (final.runCommand name { } (
          final.lib.concatLines (
            map
              # all files in linux-firmware are read-only
              (firmwarePath: ''
                if [[ -f $(realpath ${final.linux-firmware}/lib/firmware/${firmwarePath}) ]]; then
                  install -Dm0444 \
                    --target-directory=$(dirname $out/lib/firmware/${firmwarePath}) \
                    ${final.linux-firmware}/lib/firmware/${firmwarePath}
                else
                  echo "WARNING: lib/firmware/${firmwarePath} does not exist in linux-firmware ${final.linux-firmware.version}"
                fi
              '')
              paths
          )
        ));

    })
  ];
}
