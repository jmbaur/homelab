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
    (final: prev: {
      # TODO(jared): Can delete when https://github.com/NixOS/nixpkgs/pull/403807 is merged.
      kodi = prev.kodi.override { jre_headless = final.buildPackages.jdk11_headless; };
      kodi-wayland = prev.kodi-wayland.override { jre_headless = final.buildPackages.jdk11_headless; };
      kodi-gbm = prev.kodi-gbm.override { jre_headless = final.buildPackages.jdk11_headless; };

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

      tmux = prev.tmux.overrideAttrs (old: rec {
        version = old.version + "-" + builtins.substring 0 7 src.rev;
        src = final.fetchFromGitHub {
          owner = "tmux";
          repo = "tmux";
          rev = "d3c39375d5e9f4a0dcb5bd210c912d70ceca5de9";
          hash = "sha256-CTo6NJTuS2m5W6WyqTHg4G6NiRqt874pFGvVgmbKeC8=";
        };
      });

      vimPlugins = prev.vimPlugins.extend (
        _: _: {
          azy-nvim = final.vimUtils.buildVimPlugin {
            pname = "azy.nvim";
            version = "2024-08-09";
            nvimSkipModules = [
              "azy.async"
              "azy.builtins"
              "azy.ui"
            ];
            buildInputs = [ final.neovim-unwrapped.lua ];
            preInstall = ''
              make lib
              install build/afzy.so lua/azy
            '';
            src = final.fetchFromSourcehut {
              owner = "~vigoux";
              repo = "azy.nvim";
              rev = "2fe367a3642009025d5fd78b3e893edee15afd36";
              hash = "sha256-J4iMuHQFSfeDqp7Bm5635/DAdhVizP71aQoLuGy8YjY=";
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

          nvim-fzy = final.vimUtils.buildVimPlugin {
            pname = "nvim-fzy";
            version = "";
            src = final.fetchFromGitea {
              domain = "codeberg.org";
              owner = "mfussenegger";
              repo = "nvim-fzy";
              rev = "cc41ba47d2f82c05cbf3a05b24dee325f8a96e1a";
              hash = "sha256-XibxiD2ZPcipn3P9Ziiao2C0wZMLGZleBnHQe3xJoMA=";
            };
          };

          nvim-qwahl = final.vimUtils.buildVimPlugin {
            pname = "nvim-qwahl";
            version = "2025-03-26";
            src = final.fetchFromGitHub {
              owner = "mfussenegger";
              repo = "nvim-qwahl";
              rev = "1bb6c53320b948e37f32c4f8c8846343ca4df1b2";
              hash = "sha256-BKY9reEmHPUr/ysXucwXbhVsAERXNrUj+lx49QfLaoc=";
            };
          };
        }
      );

      gnome-console =
        (prev.gnome-console.overrideAttrs (old: {
          patches = (old.patches or [ ]) ++ [
            ./gnome-console-osc52.patch
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
