inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    inputs.gobar.overlays.default
    inputs.gosee.overlays.default # needed for plugin in overlayed neovim
    inputs.u-boot-nix.overlays.default
    (
      _: prev:
      prev.lib.mapAttrs (name: _: prev.callPackage ./pkgs/${name}/package.nix { }) (
        builtins.readDir ./pkgs
      )
    )
    (final: prev: {
      libfido2 = prev.libfido2.override {
        withPcsclite = final.stdenv.hostPlatform == final.stdenv.buildPlatform;
      };

      wpa_supplicant = prev.wpa_supplicant.override {
        withPcsclite = final.stdenv.hostPlatform == final.stdenv.buildPlatform;
      };

      gnupg =
        (prev.gnupg.override { enableMinimal = final.stdenv.hostPlatform != final.stdenv.buildPlatform; })
        .overrideAttrs
          (old: {
            # TODO(jared): can remove when https://github.com/NixOS/nixpkgs/pull/298001 is merged
            configureFlags =
              old.configureFlags
              ++ final.lib.optional (
                final.stdenv.hostPlatform != final.stdenv.buildPlatform
              ) "GPGRT_CONFIG=${prev.lib.getDev final.libgpg-error}/bin/gpgrt-config";
          });

      tcpdump = prev.tcpdump.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          # add support for pref64
          (final.fetchpatch {
            url = "https://github.com/the-tcpdump-group/tcpdump/commit/d879d9349ab7b3dffc4797b6a8ece758e93636c1.patch";
            hash = "sha256-Z1gHBYNUMdIkNT+miI3Iis183yJvc29OLAvg6kkvDGY=";
          })
        ];
      });

      fuzzel = prev.fuzzel.overrideAttrs (
        {
          patches ? [ ],
          ...
        }:
        {
          patches = patches ++ [
            (final.fetchpatch2 {
              name = "config-add-CTRL-to-default-keybindings";
              url = "https://codeberg.org/jmbaur/fuzzel/commit/2ecdc51a4f9ed83e94741a80648429ff7b062a14.patch";
              hash = "sha256-0cWbtc1O37zD8OCgufIurzCyuPzh5IRYPviRiOuhLpo=";
            })
          ];
        }
      );

      fnott = prev.fnott.overrideAttrs (
        {
          patches ? [ ],
          ...
        }:
        {
          patches = patches ++ [
            (final.fetchpatch2 {
              name = "add-dbus-service-file";
              url = "https://codeberg.org/sewn/fnott/commit/6a092ba5fea58764cb56cfb037fcd334a8e3d67c.patch";
              excludes = [ "README.md" ]; # fails to apply
              hash = "sha256-ZwfVOHiPmd0JulWLOXyj2HOtyKsPHPmYcvl7jBMchUQ=";
            })
          ];
        }
      );

      libgit2_1_5 = prev.libgit2.overrideAttrs (_: rec {
        version = "1.5.2";
        src = final.fetchFromGitHub {
          owner = "libgit2";
          repo = "libgit2";
          rev = "v${version}";
          hash = "sha256-zZetfuiSpiO0rRtZjBFOAqbdi+sCwl120utnXLtqMm0=";
        };
      });

      git-shell-commands = prev.callPackage ./git-shell-commands { libgit2 = final.libgit2_1_5; };

      jared-neovim = prev.callPackage ./neovim { };
      jared-neovim-all-languages = final.jared-neovim.override { supportAllLanguages = true; };

      bitwarden-wayland = prev.callPackage ./mk-wayland-variant.nix { package = final.bitwarden; };
      brave-wayland = prev.callPackage ./mk-wayland-variant.nix { package = final.brave; };
      chromium-wayland = prev.callPackage ./mk-wayland-variant.nix { package = final.chromium; };
      discord-wayland = prev.callPackage ./mk-wayland-variant.nix { package = final.discord; };
      google-chrome-wayland = prev.callPackage ./mk-wayland-variant.nix {
        package = final.google-chrome;
      };
      signal-desktop-wayland = prev.callPackage ./mk-wayland-variant.nix {
        package = final.signal-desktop;
      };
      slack-wayland = prev.callPackage ./mk-wayland-variant.nix { package = final.slack; };

      mkWebApp = prev.callPackage ./mk-web-app.nix { chromium = final.chromium-wayland; };
      discord-webapp = final.mkWebApp "discord" "https://discord.com/app";
      outlook-webapp = final.mkWebApp "outlook" "https://outlook.office365.com/mail";
      slack-webapp = final.mkWebApp "slack" "https://app.slack.com/client";
      teams-webapp = final.mkWebApp "teams" "https://teams.microsoft.com";

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

      jmbaur-ssh-keys = final.writeText "jmbaur.keys" ''
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmnCgu1Jbl73bx7ijawfVEIHRFjAJ6qmXmYViGyykyA2DQgR3uzfoe09S9oITgHCIQUA53dy0kjQBhwVZJpXFV1eW+rxKBa024ob1yoBxCg6X5+lhBf5sgIEO48nNuDnYisINdbmxL5QqZjM7QnGukmWR5XjwmI83coWiAgbBueWKM70dxi5UgpBG89/RXgpz3OtEK16ZaW1yWyPwi1AY3xzz5HITUDw4AhhpohI/8uq15eDvgZXJwC9E/j9Frh1HhemWry34/d2RZe1w7l8glMvsEdN1NnfjzjQeZhv0EsbCySpqU3b9e0YMn3hda/FC12V9fuAJckAyh1oPPY2B1O+4nYGcuUv50NNnVB1UsSRKNlL5zHkIBpHB+3jba0tHeo/UUQBafmoTUWZh5k4U3bA2CWZ9N2T0SW632LAFUn5KeZoYgl/v0/uzhsXe87MDvmI869lpaOxbzfM3Mnu/XAPYPraUXdeW8a9fL3R/4f/vPSP/V5VfRzBCNa1AJDSdH5/IwpwqCrlO8woixjRYcknnZLNqkR92iqsNYUTP3+xYHHocRBPcLsuGtdbl81QxW9jtk7Ls9q9A/gMYk4WgiVXtbrmVg3FlNsi0TnjJQgMYnsRen9z904AouQXGf8CrFlmxJvwWlK1RU+Q29+PemjVaTr3vME0HMpyEny0+Wmw==
      '';
    })
  ];
}
