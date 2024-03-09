inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    inputs.gobar.overlays.default
    inputs.gosee.overlays.default # needed for plugin in overlayed neovim
    inputs.u-boot-nix.overlays.default
    (final: prev: {
      stevenblack-blocklist = prev.callPackage ./stevenblack-blocklist.nix { };

      nixos-kexec = prev.callPackage ./nixos-kexec { };

      libfido2 = prev.libfido2.override {
        withPcsclite = prev.stdenv.hostPlatform == prev.stdenv.buildPlatform;
      };

      wpa_supplicant = prev.wpa_supplicant.override {
        withPcsclite = prev.stdenv.hostPlatform == prev.stdenv.buildPlatform;
      };

      gnupg = prev.gnupg.override {
        enableMinimal = prev.stdenv.hostPlatform != prev.stdenv.buildPlatform;
      };

      # Can be deleted when this PR is merged: https://github.com/NixOS/nixpkgs/pull/284160
      greetd = prev.greetd // {
        wlgreet = prev.greetd.wlgreet.overrideAttrs ({ nativeBuildInputs ? [ ], buildInputs ? [ ], ... }: {
          nativeBuildInputs = nativeBuildInputs ++ [ prev.buildPackages.autoPatchelfHook ];
          buildInputs = buildInputs ++ [ prev.gcc-unwrapped ];
          runtimeDependencies = map prev.lib.getLib (with prev; [ gcc-unwrapped wayland libxkbcommon ]);
        });
      };

      labwc = prev.labwc.overrideAttrs ({ patches ? [ ], ... }: {
        patches = patches ++ [
          (prev.fetchpatch2 {
            name = "Add-omnipresent-flag-for-views";
            url = "https://github.com/labwc/labwc/commit/bad8f334ead5587208ec62fb01ddf9dd2be5ff67.patch";
            hash = "sha256-Djx+0cHklJCu/nmpwhO0dlHETeJnp5rG4hTjS3Wadg0=";
          })
          (prev.fetchpatch2 {
            name = "Add-touchpad-device-type";
            url = "https://github.com/labwc/labwc/commit/6faee17d20637df35e27cd2cac462323e4d665a1.patch";
            hash = "sha256-5HptxaEK7zH1eoyxYYyYZpKECE8MXznj6zLVDC0Kkyg=";
          })
        ];
      });

      fuzzel = prev.fuzzel.overrideAttrs ({ patches ? [ ], ... }: {
        patches = patches ++ [
          (prev.fetchpatch2 {
            name = "config-add-CTRL-to-default-keybindings";
            url = "https://codeberg.org/jmbaur/fuzzel/commit/2ecdc51a4f9ed83e94741a80648429ff7b062a14.patch";
            hash = "sha256-0cWbtc1O37zD8OCgufIurzCyuPzh5IRYPviRiOuhLpo=";
          })
        ];
      });

      fnott = prev.fnott.overrideAttrs ({ patches ? [ ], ... }: {
        patches = patches ++ [
          (prev.fetchpatch2 {
            name = "add-dbus-service-file";
            url = "https://codeberg.org/sewn/fnott/commit/6a092ba5fea58764cb56cfb037fcd334a8e3d67c.patch";
            excludes = [ "README.md" ]; # fails to apply
            hash = "sha256-ZwfVOHiPmd0JulWLOXyj2HOtyKsPHPmYcvl7jBMchUQ=";
          })
        ];
      });

      libgit2_1_5 = prev.libgit2.overrideAttrs (_: rec {
        version = "1.5.2";
        src = prev.fetchFromGitHub {
          owner = "libgit2";
          repo = "libgit2";
          rev = "v${version}";
          hash = "sha256-zZetfuiSpiO0rRtZjBFOAqbdi+sCwl120utnXLtqMm0=";
        };
      });

      git-shell-commands = prev.callPackage ./git-shell-commands {
        libgit2 = final.libgit2_1_5;
      };
      pb = prev.writeShellScriptBin "pb" "${prev.curl}/bin/curl --data-binary @- https://paste.rs/";
      tmux-jump = prev.callPackage ./tmux-jump.nix { };
      kinesis-kint41-jmbaur = prev.callPackage ./kinesis-kint41-jmbaur.nix { };
      macgen = prev.callPackage ./macgen.nix { };
      pomo = prev.callPackage ./pomo { };
      v4l-show = prev.callPackage ./v4l-show.nix { };
      wip = prev.writeShellScriptBin "wip" (builtins.readFile ./wip.bash);

      jared-neovim = prev.callPackage ./neovim {
        neovim-unwrapped = inputs.neovim.packages.${prev.system}.neovim;
      };
      jared-neovim-all-languages = final.jared-neovim.override { supportAllLanguages = true; };

      bitwarden-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.bitwarden; };
      brave-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.brave; };
      chromium-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.chromium; };
      discord-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.discord; };
      google-chrome-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.google-chrome; };
      signal-desktop-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.signal-desktop; };
      slack-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.slack; };
      spotify-wayland = prev.callPackage ./mk-wayland-variant.nix { package = prev.spotify; };

      mkWebApp = prev.callPackage
        ./mk-web-app.nix
        { chromium = final.chromium-wayland; };
      discord-webapp = final.mkWebApp
        "discord"
        "https://discord.com/app";
      outlook-webapp = final.mkWebApp
        "outlook"
        "https://outlook.office365.com/mail";
      slack-webapp = final.mkWebApp
        "slack"
        "https://app.slack.com/client";
      spotify-webapp = final.mkWebApp
        "spotify"
        "https://open.spotify.com";
      teams-webapp = final.mkWebApp
        "teams"
        "https://teams.microsoft.com";

      grafana-dashboards = prev.callPackage ./grafana-dashboards { };

      ubootEnvTools = prev.callPackage ./uboot-env-tools.nix { };

      uboot-clearfog_uart = prev.uboot-clearfog.override {
        extraStructuredConfig = with prev.lib.kernel; {
          MVEBU_SPL_BOOT_DEVICE_MMC = no;
          MVEBU_SPL_BOOT_DEVICE_UART = yes;
        };
      };

      mrvlUart = prev.callPackage ./mrvl-uart.nix { };

      marvellBinaries = prev.fetchFromGitHub {
        owner = "MarvellEmbeddedProcessors";
        repo = "binaries-marvell";
        # branch: binaries-marvell-armada-SDK10.0.1.0
        rev = "b3d449e72196db5d48a2087c3df40b935834d304";
        hash = "sha256-m8NdvFSVo5+TPtpiGevyzXIMR1YcSQu5Xi5ewUX983Y=";
      };

      mvDdrMarvell = prev.applyPatches rec {
        src = prev.fetchgit {
          url = "https://github.com/MarvellEmbeddedProcessors/mv-ddr-marvell";
          rev = "bfcf62051be835f725005bb5137928f7c27b792e";
          hash = "sha256-a6Hjx4/4uxQqNZRRa331B7aOtsyaUNhGh3izOSBrL3c=";
        };
        patches = [
          (prev.substituteAll {
            src = ./mv-ddr-marvell-version.patch;
            shortRev = builtins.substring 0 7 src.rev;
          })
        ];
      };

      cn9130CfProSdFirmware = prev.callPackage ./cn913x/firmware.nix { spi = false; };
      cn9130CfProSpiFirmware = prev.callPackage ./cn913x/firmware.nix { spi = true; };

      mcbinFirmware = prev.callPackage ./mcbin-firmware { };

      jmbaur-keybase-pgp-keys = prev.fetchurl {
        url = " https://keybase.io/jaredbaur/pgp_keys.asc ";
        sha256 = " sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
      };

      jmbaur-ssh-keys = prev.writeText "jmbaur.keys" ''
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIBhCHaXn5ghEJQVpVZr4hOajD6Zp/0PO4wlymwfrg/S5AAAABHNzaDo=
        sk-ssh-ed25519@openssh.com AAAAGnNrLXNzaC1lZDI1NTE5QG9wZW5zc2guY29tAAAAIHRlxBSW3BzX33FG7444p/M5lb9jYR5OkjS2jPpnuXozAAAABHNzaDo=
        ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDmnCgu1Jbl73bx7ijawfVEIHRFjAJ6qmXmYViGyykyA2DQgR3uzfoe09S9oITgHCIQUA53dy0kjQBhwVZJpXFV1eW+rxKBa024ob1yoBxCg6X5+lhBf5sgIEO48nNuDnYisINdbmxL5QqZjM7QnGukmWR5XjwmI83coWiAgbBueWKM70dxi5UgpBG89/RXgpz3OtEK16ZaW1yWyPwi1AY3xzz5HITUDw4AhhpohI/8uq15eDvgZXJwC9E/j9Frh1HhemWry34/d2RZe1w7l8glMvsEdN1NnfjzjQeZhv0EsbCySpqU3b9e0YMn3hda/FC12V9fuAJckAyh1oPPY2B1O+4nYGcuUv50NNnVB1UsSRKNlL5zHkIBpHB+3jba0tHeo/UUQBafmoTUWZh5k4U3bA2CWZ9N2T0SW632LAFUn5KeZoYgl/v0/uzhsXe87MDvmI869lpaOxbzfM3Mnu/XAPYPraUXdeW8a9fL3R/4f/vPSP/V5VfRzBCNa1AJDSdH5/IwpwqCrlO8woixjRYcknnZLNqkR92iqsNYUTP3+xYHHocRBPcLsuGtdbl81QxW9jtk7Ls9q9A/gMYk4WgiVXtbrmVg3FlNsi0TnjJQgMYnsRen9z904AouQXGf8CrFlmxJvwWlK1RU+Q29+PemjVaTr3vME0HMpyEny0+Wmw==
      '';
    })
  ];
}
