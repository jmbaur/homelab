inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    # needed by some stuff below
    inputs.u-boot-nix.overlays.default
    inputs.ipwatch.overlays.default
    # auto-added packages
    (
      final: prev:
      prev.lib.packagesFromDirectoryRecursive {
        inherit (final) callPackage;
        directory = ./by-name;
      }
    )

    # cross-compilation fixes
    (_final: prev: {
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
      cros-ec-fizz = prev.cros-ec.override { board = "fizz"; };

      # TODO(jared): remove when we have https://github.com/NixOS/nixpkgs/pull/465400
      termbench-pro = prev.termbench-pro.overrideAttrs (old: {
        buildInputs = final.lib.filter (drv: drv.pname != final.glaze.pname) (old.buildInputs or [ ]) ++ [
          (final.glaze.override { enableSSL = false; })
        ];
      });

      # https://github.com/NixOS/nixpkgs/issues/366902
      qemu-user = prev.qemu-user.overrideAttrs (old: {
        configureFlags =
          old.configureFlags
          ++ final.lib.optionals (with final.stdenv.hostPlatform; isAarch64 && isStatic) [ "--disable-pie" ];
      });

      vimPlugins = prev.vimPlugins.extend (
        _: _: {
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
            ./gnome-console-copy-on-select.patch
            ./gnome-console-colors.patch
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
        postInstall = (old.postInstall or "") + ''
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
