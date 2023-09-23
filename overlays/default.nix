inputs: with inputs; {
  default = nixpkgs.lib.composeManyExtensions [
    gosee.overlays.default # needed for plugin in overlayed neovim
    (final: prev:
      let
        out-of-tree = prev.callPackage ./out-of-tree.nix { };
      in
      {
        inherit (out-of-tree)
          cicada
          coredns-utils
          depthcharge-tools
          fdroidcl
          flarectl
          stevenblack-blocklist
          u-rootInitramfs
          xremap
          yamlfmt
          ;

        nixos-kexec = prev.callPackage ./nixos-kexec { };

        # provide dbus-activation for fnott
        fnott-dbus = prev.symlinkJoin {
          name = "fnott-dbus";
          paths = [ prev.fnott ];
          postBuild =
            let
              fnott-dbus-service = prev.writeText "fnott.service" ''
                [D-BUS Service]
                Name=org.freedesktop.Notifications
                Exec=${prev.fnott}/bin/fnott
              '';
            in
            ''
              mkdir -p $out/share/dbus-1/services
              ln -sf ${fnott-dbus-service} $out/share/dbus-1/services/fnott.service
            '';
        };

        libgit2_1_5 = prev.libgit2.overrideAttrs (_: rec {
          version = "1.5.2";
          src = prev.fetchFromGitHub {
            owner = "libgit2";
            repo = "libgit2";
            rev = "v${version}";
            hash = "sha256-zZetfuiSpiO0rRtZjBFOAqbdi+sCwl120utnXLtqMm0=";
          };
        });

        bitwarden-bemenu = prev.callPackage ./bitwarden-bemenu.nix { };
        git-get = prev.callPackage ./git-get { };
        git-shell-commands = prev.callPackage ./git-shell-commands {
          libgit2 = final.libgit2_1_5;
        };
        ixio = prev.writeShellScriptBin "ixio" "${prev.curl}/bin/curl -F 'f:1=<-' ix.io";
        j = prev.callPackage ./j.nix { };
        kinesis-kint41-jmbaur = prev.callPackage ./kinesis-kint41-jmbaur.nix { };
        macgen = prev.callPackage ./macgen.nix { };
        mirror-to-x = prev.callPackage ./mirror-to-x.nix { };
        pomo = prev.callPackage ./pomo { };
        v4l-show = prev.callPackage ./v4l-show.nix { };
        wip = prev.writeShellScriptBin "wip" ''git commit --no-verify --no-gpg-sign --all --message "WIP"; git push'';
        dookie = prev.callPackage ./dookie { };

        vimPlugins = prev.vimPlugins // {
          jmbaur-settings = prev.vimUtils.buildVimPluginFrom2Nix {
            name = "jmbaur-settings";
            src = ./neovim/settings;
          };
        };

        neovim = prev.callPackage ./neovim { };
        neovim-all-languages = prev.callPackage ./neovim { supportAllLanguages = true; };

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

        cn913x_build_repo = prev.fetchFromGitHub {
          owner = "solidrun";
          repo = "cn913x_build";
          rev = "d6d0577e6b6e86d29837618e9a02f5ee4ac136cb";
          hash = "sha256-5PGu7XQxtg0AP9RovDDqmPuVnrNQow1bYaorAmUFQ7Q=";
        };

        cn9130ClearfogProFirmware = prev.callPackage ./cn9130-clearfog-pro-firmware.nix { inherit (final) cn913x_build_repo; };

        bpiR3Firmware = prev.callPackage ./bpi-r3-firmware.nix { };

        # linux_orangepi-5 = prev.callPackage ./kernels/linux-orangepi-5.nix { };

        jmbaur-keybase-pgp-keys = prev.fetchurl {
          url = "https://keybase.io/jaredbaur/pgp_keys.asc";
          sha256 = "sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
        };
        jmbaur-github-ssh-keys = prev.fetchurl {
          url = "https://github.com/jmbaur.keys";
          sha256 = "sha256-B80abOJCi8MoPQsGOVTKtufchA/xnpMnap+n2RY0Wcw=";
        };
      })
  ];
}
