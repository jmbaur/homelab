inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    # from flake inputs; some are needed by the overlays below
    inputs.ipwatch.overlays.default
    inputs.mixos.overlays.default
    inputs.neovim-nightly-overlay.overlays.default
    inputs.quartus-nix.overlays.default
    inputs.u-boot-nix.overlays.default
    # auto-added packages
    (
      final: prev:
      prev.lib.packagesFromDirectoryRecursive {
        inherit (final) callPackage;
        directory = ./by-name;
      }
    )
    (
      final: prev:
      inputs.nixpkgs.lib.genAttrs
        [
          "lua5"
          "lua5_1"
          "luajit_2_1"
          "luajit_2_0"
          "lua5_2"
          "lua5_3"
          "lua5_4"
          "lua5_5"
        ]
        (
          lua:
          prev.${lua}.override {
            packageOverrides =
              luafinal: _luaprev:
              final.lib.packagesFromDirectoryRecursive {
                inherit (luafinal) callPackage;
                directory = ./lua;
              };
          }
        )
    )

    # cross-compilation fixes
    (_final: prev: {
      # The hotdoc docs run a freshly built tool (generate_md_opcodes_table),
      # which needs an exe_wrapper when cross-compiling.
      orc = prev.orc.override {
        buildDevDoc = prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform;
      };

      perlPackages = prev.perlPackages.overrideScope (
        _: perlPackagesPrev: {
          NetDNS = perlPackagesPrev.NetDNS.overrideAttrs (old: {
            patches = (old.patches or [ ]) ++ [ ./perl-netdns-fix-cross.patch ];
          });
        }
      );
    })

    # GCC 16 fixes
    (final: prev: {
      # TODO: drop once nixpkgs contour includes https://github.com/contour-terminal/contour/pull/1944
      contour = prev.contour.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (final.fetchpatch {
            url = "https://github.com/contour-terminal/contour/commit/38e543a71bffee72be34154f929493d3a1ea5c4a.patch";
            includes = [ "src/vtbackend/Image.cpp" ];
            hash = "sha256-C6FzHdOdKXaBb3ybqodd9xQ+E6XfDBH49ZgZLV5K8Rk=";
          })
        ];
      });
    })

    # all other packages
    (final: prev: {
      cros-ec-fizz = prev.cros-ec.override { board = "fizz"; };

      homelab-utils = final.callPackages ./homelab-utils.nix { };

      chickenPackages_6 = final.lib.recurseIntoAttrs (
        prev.chickenPackages_6.overrideScope (
          cfinal: cprev: {
            chickenEggs = final.lib.recurseIntoAttrs (
              cprev.chickenEggs.overrideScope (
                final.lib.const (
                  final.lib.const {
                    dbus = cfinal.callPackage ./chicken/dbus { };
                    gpiocdev = cfinal.callPackage ./chicken/gpiocdev { };
                    libsodium = cfinal.callPackage ./chicken/libsodium { };
                    qrencode = cfinal.callPackage ./chicken/qrencode { };
                  }
                )
              )
            );
          }
        )
      );

      fnlfmt = prev.fnlfmt.overrideAttrs rec {
        version = "0.3.2-${builtins.substring 0 9 src.rev}";

        src = final.fetchFromSourcehut {
          owner = "~technomancy";
          repo = "fnlfmt";
          rev = "e059775b9ce38cdcf3c1d5458ca2e5f2ecf698b3";
          hash = "sha256-PG/bEkGkgaIBAlQGvDN9C+As3H6hGUskF8vhMD4mZmY=";
        };
      };

      # TODO: drop once nixpkgs packages an orbit release that includes
      # https://github.com/fleetdm/fleet/pull/54098 (NixOS support).
      fleet-orbit =
        (prev.fleet-orbit.override { buildGoModule = final.buildGo127Module; }).overrideAttrs
          (old: {
            version = "1.61.0-unstable-2026-10-07";

            src = final.fetchFromGitHub {
              owner = "fleetdm";
              repo = "fleet";
              rev = "1bfc70f82a9f4f2347b05075bf9f233f96281cc6";
              hash = "sha256-dHciCev0wt4Tx/9opi3lkews54inAJ7J1yks01DpqqE=";
            };

            vendorHash = "sha256-/Q1VjPi/ID3ApO5n8DdFcPK51+CAiTC0SO9RTsNw9BE=";

            # Upstream now handles the NIX_ORBIT_* overrides, sudo and xdg-open
            # on NixOS, so only the script interpreter patch is still needed.
            patches =
              builtins.filter (patch: final.lib.hasSuffix "-scripts-nixos.patch" (toString patch)) old.patches
              ++ [
                # TODO: drop once upstreamed to fleetdm/fleet
                ./fleet-orbit-xdg-runtime-dir.patch
              ];

            postPatch = "";
          });

      # fleet-desktop takes its version and src from fleet-orbit
      fleet-desktop =
        (prev.fleet-desktop.override { buildGoModule = final.buildGo127Module; }).overrideAttrs
          {
            vendorHash = "sha256-/Q1VjPi/ID3ApO5n8DdFcPK51+CAiTC0SO9RTsNw9BE=";
          };

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
