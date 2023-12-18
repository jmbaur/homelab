inputs: {
  default = inputs.nixpkgs.lib.composeManyExtensions [
    inputs.gosee.overlays.default # needed for plugin in overlayed neovim
    inputs.u-boot-nix.overlays.default
    (final: prev: {
      stevenblack-blocklist = prev.callPackage ./stevenblack-blocklist.nix { };

      nixos-kexec = prev.callPackage ./nixos-kexec { };

      labwc = prev.labwc.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "Add-omnipresent-flag-for-views";
            url = "https://github.com/labwc/labwc/commit/bad8f334ead5587208ec62fb01ddf9dd2be5ff67.patch";
            hash = "sha256-Djx+0cHklJCu/nmpwhO0dlHETeJnp5rG4hTjS3Wadg0=";
          })
          (prev.fetchpatch2 {
            name = "Add-touchpad-device-type";
            url = "https://github.com/jmbaur/labwc/commit/57394fc05261c63221b08a6821ad86a4831cf5fc.patch";
            hash = "sha256-siAV5VNSj+pcLxfM5Ljl8VczWlnczApkDu6xOD5pQvM=";
          })
        ];
      });

      labwc-gtktheme = prev.callPackage ./labwc-gtktheme.nix { };

      fuzzel = prev.fuzzel.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
          (prev.fetchpatch2 {
            name = "config-add-CTRL-to-default-keybindings";
            url = "https://codeberg.org/jmbaur/fuzzel/commit/2ecdc51a4f9ed83e94741a80648429ff7b062a14.patch";
            hash = "sha256-0cWbtc1O37zD8OCgufIurzCyuPzh5IRYPviRiOuhLpo=";
          })
        ];
      });

      fnott = prev.fnott.overrideAttrs (old: {
        patches = (old.patches or [ ]) ++ [
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
      j = prev.callPackage ./j.nix { };
      kinesis-kint41-jmbaur = prev.callPackage ./kinesis-kint41-jmbaur.nix { };
      macgen = prev.callPackage ./macgen.nix { };
      pomo = prev.callPackage ./pomo { };
      v4l-show = prev.callPackage ./v4l-show.nix { };
      wip = prev.writeShellScriptBin "wip" ''git commit --no-verify --no-gpg-sign --all --message "WIP"; git push'';

      jared-neovim = prev.callPackage ./neovim {
        neovim-unwrapped = inputs.neovim.packages.${prev.system}.neovim;
      };
      jared-neovim-all-languages = final.jared-neovim.override { supportAllLanguages = true; };

      mkWaylandVariant = prev.callPackage ./mk-wayland-variant.nix { };
      brave-wayland = final.mkWaylandVariant
        prev.brave;
      chromium-wayland = final.mkWaylandVariant
        prev.chromium;
      google-chrome-wayland = final.mkWaylandVariant
        prev.google-chrome;
      bitwarden-wayland = final.mkWaylandVariant
        prev.bitwarden;
      discord-wayland = final.mkWaylandVariant
        prev.discord;
      signal-desktop-wayland = final.mkWaylandVariant
        prev.signal-desktop;
      slack-wayland = final.mkWaylandVariant
        prev.slack;

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

      ubootClearfog = (prev.ubootClearfog.override {
        filesToInstall = [ "u-boot-with-spl.kwb" ];
        # UEFI support
        extraConfig = ''
          CONFIG_BLK=y
          CONFIG_CMD_BOOTEFI=y
          CONFIG_EFI_CAPSULE_AUTHENTICATE=y
          CONFIG_EFI_CAPSULE_ON_DISK=y
          CONFIG_EFI_LOADER=y
          CONFIG_EFI_SECURE_BOOT=y
          CONFIG_FIT=y
          CONFIG_FIT_SIGNATURE=y
          CONFIG_PARTITIONS=y
          CONFIG_RSA=y
        '';
      }).overrideAttrs (old: {
        # needed for CONFIG_EFI_SECURE_BOOT
        nativeBuildInputs = old.nativeBuildInputs ++ [ prev.buildPackages.perl ];
      });
      ubootClearfogUart = final.ubootClearfog.override {
        extraConfig = final.ubootClearfog.extraConfig + ''
          CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=n
          CONFIG_MVEBU_SPL_BOOT_DEVICE_UART=y
        '';
      };
      ubootClearfogSpi =
        # u-boot 0MiB    - 2MiB
        # env    2MiB    - 2.25MiB
        # empty  2.25MiB - 4MiB
        let
          envSize = 256 * 1024; # 256KiB in bytes
          envOffset = 2 * 1024 * 1024; # 2MiB in bytes
          ubootSize = envOffset; # ubootSize equals envOffset since uboot starts from zero
        in
        final.ubootClearfog.override {
          defconfig = "clearfog_spi_defconfig";
          extraConfig =
            final.ubootClearfog.extraConfig + ''
              CONFIG_OF_LIBFDT=y
              CONFIG_CMD_MTDPARTS=y
              CONFIG_FDT_FIXUP_PARTITIONS=y
              CONFIG_ENV_OFFSET=0x${prev.lib.toHexString envOffset}
              CONFIG_ENV_SIZE=0x${prev.lib.toHexString envSize}
              CONFIG_MTDIDS_DEFAULT="nor0=w25q32"
              CONFIG_MTDPARTS_DEFAULT="w25q32:${toString ubootSize}(u-boot),${toString envSize}(u-boot-env),-(empty)"
            '';
          postInstall = let blockSize = 512; in ''
            dd bs=${toString blockSize} count=${toString (ubootSize / blockSize)} if=/dev/zero of=$out/firmware.bin
            dd conv=notrunc if=$out/u-boot-with-spl.kwb of=$out/firmware.bin
          '';
          extraPatches = [ ./clearfog-spi-mtd-fixup.patch ];
        };

      cn9130CfProSdFirmware = prev.callPackage ./cn913x/firmware.nix { spi = false; };
      cn9130CfProSpiFirmware = prev.callPackage ./cn913x/firmware.nix { spi = true; };

      mrvlUart = prev.callPackage ./mrvl-uart.nix { };

      bpiR3Firmware = prev.callPackage ./bpi-r3-firmware.nix { };

      # linux_orangepi-5 = prev.callPackage ./kernels/linux-orangepi-5.nix { };

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
