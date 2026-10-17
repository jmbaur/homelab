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

      # rdma-core doesn't cross-compile (CMake's FindPython rejects the build
      # platform's interpreter), and RDMA capture isn't something we need.
      libpcap = prev.libpcap.override (
        prev.lib.optionalAttrs (!prev.stdenv.buildPlatform.canExecute prev.stdenv.hostPlatform) {
          withRdma = false;
        }
      );

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
        version = "0.4.0";

        src = final.fetchFromSourcehut {
          owner = "~technomancy";
          repo = "fnlfmt";
          rev = version;
          hash = "sha256-8ZDT7CVWWKaFclU4yCgT9JUR+jCwMrA+6F11os65JHQ=";
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

      # TODO: drop once nixpkgs has oo7 >= 0.7.0, which resolves aliases
      # (e.g. /org/freedesktop/secrets/aliases/default, used by go-keyring) in
      # Lock and Unlock. oo7-server, oo7-portal and oo7-pam inherit src and
      # cargoDeps from here.
      oo7 = prev.oo7.overrideAttrs (
        finalAttrs: _: {
          version = "0.7.0.beta";

          src = final.fetchFromGitHub {
            owner = "linux-credentials";
            repo = "oo7";
            tag = finalAttrs.version;
            hash = "sha256-HdKWP+4A7pJpGRMTIm6ST1H5PZLdbPz2sbTZv5+2LaA=";
          };

          cargoDeps = final.rustPlatform.fetchCargoVendor {
            inherit (finalAttrs) pname version src;
            hash = "sha256-X+yNxuVqfOo9uSPx3FZ9RlIg7sQJTK6xNiLgsxENWac=";
          };
        }
      );

      # oo7-pam links against libpam since 0.7.0
      oo7-pam = prev.oo7-pam.overrideAttrs (old: {
        buildInputs = old.buildInputs ++ [ final.pam ];
      });

      # TODO: drop once nixpkgs has tmux >= 3.8, which has builtin light and
      # dark themes that follow the terminal's.
      tmux = prev.tmux.overrideAttrs (
        finalAttrs: _: {
          version = "3.8";

          src = final.fetchFromGitHub {
            owner = "tmux";
            repo = "tmux";
            tag = finalAttrs.version;
            hash = "sha256-pv2wlr3coo+E0pfpb58giJJQn9PGgMFqtVA6nk+9JdE=";
          };
        }
      );
    })
  ];
}
