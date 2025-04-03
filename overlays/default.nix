inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    # needed by some stuff below
    inputs.u-boot-nix.overlays.default
    # auto-added packages
    (
      final: prev:
      prev.lib.packagesFromDirectoryRecursive {
        inherit (final) callPackage;
        directory = ./pkgs;
      }
    )

    # cross-compilation fixes
    (_: prev: {
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
      patchNameFromSubject =
        name:
        (final.lib.replaceStrings [ " " "[" "]" "," "/" ":" ] [ "-" "" "" "_" "_" "" ] name) + ".patch";

      way-displays = prev.way-displays.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [ ./way-displays-default-dpi.patch ];
      });

      vimPlugins = prev.vimPlugins.extend (
        _: _: {
          vim-dir = final.vimUtils.buildVimPlugin {
            pname = "vim-dir";
            version = "2025-01-23";
            src = final.fetchFromGitHub {
              owner = "habamax";
              repo = "vim-dir";
              rev = "c0ce178b9df864de5b5b89460f22ccc7ac10757c";
              hash = "sha256-Qxb6ooB6pfDpKTioD0xuzC4O1dtDxMcKVWlB0IxyKhA=";
            };
          };

          lsp = final.vimUtils.buildVimPlugin {
            pname = "lsp";
            version = "2025-03-12";
            src = final.fetchFromGitHub {
              owner = "yegappan";
              repo = "lsp";
              rev = "9f3d92ed7f3ba0ba5b496f0fd2150ce56b049832";
              hash = "sha256-dXm03apOI6zDyBXL6LiSPABmT9wCin6tjDVD2smrSU0=";
            };
          };

          bpftrace-vim = final.vimUtils.buildVimPlugin {
            pname = "bpftrace.vim";
            version = "2019-06-19";
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
          patches = (old.patches or [ ]) ++ [
            ./gnome-console-osc52.patch
            # ./gnome-console-black-background.patch
            ./gnome-console-copy-on-select.patch
          ];
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
          + ''
            substituteInPlace $out/share/dbus-1/services/fr.emersion.mako.service \
              --replace-fail "Exec=$out/bin/mako" "SystemdService=mako.service"
          '';
      });

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
