inputs: with inputs; {
  default = nixpkgs.lib.composeManyExtensions [
    gosee.overlays.default
    tinyboot.overlays.default
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
          flashrom-cros
          flashrom-dasharo
          stevenblack-blocklist
          u-rootInitramfs
          xremap
          yamlfmt
          ;

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

        libgit2_1_5_2 = prev.libgit2.overrideAttrs (_: rec {
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
          libgit2 = final.libgit2_1_5_2;
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

        ubootCoreboot = prev.buildUBoot {
          defconfig = "coreboot_defconfig";
          extraConfig = ''
            CONFIG_BLK=y
            CONFIG_CMD_BOOTEFI=y
            CONFIG_CMD_QFW=y
            CONFIG_EFI_LOADER=y
            CONFIG_PARTITIONS=y
          '';
          extraMeta.platforms = [ "x86_64-linux" ];
          filesToInstall = [ "u-boot-dtb.bin" ];
        };

        # Enable fit images (w/signatures) and modify some hardware.
        # - CON2 is located nearest the CPU
        # - CON3 is located nearest the edge of the device
        ubootClearfog = prev.ubootClearfog.override {
          extraConfig = ''
            CONFIG_CLEARFOG_CON2_PCI=y
            CONFIG_CLEARFOG_CON3_PCI=y
            CONFIG_CLEARFOG_CON2_SATA=n
            CONFIG_CLEARFOG_CON3_SATA=n
            CONFIG_CLEARFOG_SFP_25GB=y
            CONFIG_FIT=y
            CONFIG_FIT_SIGNATURE=y
            CONFIG_RSA=y
          '';
          # default boot device is mmc
          extraMeta.bootDevice = "mmc";
        };
        ubootClearfogUart = prev.ubootClearfog.override {
          extraConfig = final.ubootClearfog.extraConfig + ''
            CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=n
            CONFIG_MVEBU_SPL_BOOT_DEVICE_UART=y
          '';
          extraMeta.bootDevice = "uart";
        };
        ubootClearfogSpi = prev.ubootClearfog.override {
          extraConfig = final.ubootClearfog.extraConfig + ''
            CONFIG_MVEBU_SPL_BOOT_DEVICE_MMC=n
            CONFIG_MVEBU_SPL_BOOT_DEVICE_SPI=y
          '';
          postInstall = ''
            dd bs=1M count=4 if=/dev/zero of=$out/spi.img
            dd conv=notrunc if=$out/u-boot-spl.kwb of=$out/spi.img
          '';
          extraMeta.bootDevice = "spi";
        };

        cn913x_build_repo = prev.fetchFromGitHub {
          owner = "solidrun";
          repo = "cn913x_build";
          rev = "0a5047c2ed2c4095f404a457f38776e9a7d6d731";
          sha256 = "sha256-bViiPfpPYo/qScjI+CXJIiDKh2recXGGB4Bj1L9gQ5A=";
        };
        ubootCN9130_CF_Pro = prev.callPackage ./uboot-cn9130-cf-pro.nix { inherit (final) cn913x_build_repo; };

        # linux_orangepi-5 = prev.callPackage ./kernels/linux-orangepi-5.nix { };

        linuxboot-qemu-aarch64-fitimage = final.mkFitImage {
          boardName = "qemu-aarch64";
          kernel = final.tinyboot-kernel;
          initramfs = "${final.tinyboot-initramfs.override { tinybootTTY = "ttyAMA0"; }}/initrd";
          # NOTE: See here as to why qemu needs to be in depsBuildBuild and
          # not nativeBuildInputs:
          # https://github.com/NixOS/nixpkgs/pull/146583
          dtb = prev.callPackage
            ({ runCommand, qemu }: runCommand "qemu-aarch64.dtb" { depsBuildBuild = [ qemu ]; } ''
              qemu-system-aarch64 \
                -M virt,secure=on,virtualization=on,dumpdtb=$out \
                -cpu cortex-a53 -m 4096M -nographic
            '')
            { };
        };
        linuxboot-mediatek-fitimage = final.mkFitImage {
          boardName = "mediatek";
          kernel = final.tinyboot-kernel;
          initramfs = "${final.tinyboot-initramfs}/initrd";
          dtbPattern = "(mt8183|mt8192)";
        };

        edk2-uefi-coreboot-payload = prev.callPackage ./edk2-coreboot.nix { };

        mkFitImage = prev.callPackage ./fitimage { };
        buildCoreboot = prev.callPackage ./coreboot {
          # built with meson, includes pkg-config support
          flashrom = final.flashrom-cros;
        };
        coreboot-qemu-x86 = final.buildCoreboot {
          boardName = "qemu-x86";
          configfile = ./coreboot/qemu-x86.config;
          postInstall = ''
            ./build/util/cbfstool/cbfstool $out/coreboot.rom add-flat-binary \
              -f ${final.ubootCoreboot}/u-boot-dtb.bin -n fallback/payload -c lzma -l 0x1110000 -e 0x1110000
          '';
        };
        coreboot-qemu-aarch64 = final.buildCoreboot {
          inherit (final.linuxboot-qemu-aarch64-fitimage) boardName;
          configfile = ./coreboot/qemu-aarch64.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-qemu-aarch64-fitimage}/uImage"
          '';
        };
        coreboot-volteer-elemi = final.buildCoreboot {
          boardName = "volteer-elemi";
          configfile = ./coreboot/volteer-elemi.config;
          extraConfig =
            let
              vbt = prev.fetchurl {
                url = "https://github.com/intel/FSP/raw/d85493d0605921f46afab3445be01da90f0a8062/TigerLakeFspBinPkg/Client/SampleCode/Vbt/Vbt.bin";
                sha256 = "sha256-IDp05CcwaTOucvXF8MmsTg1qyYKXU3E5xw2ZUisUXt4=";
              };
            in
            ''
              CONFIG_INTEL_GMA_VBT_FILE="${vbt}"
              CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
              CONFIG_LINUX_INITRD="${final.tinyboot-initramfs}/initrd"
            '';
          postInstall = ''
            ./build/util/cbfstool/cbfstool $out/coreboot.rom add-flat-binary \
              -f ${final.ubootCoreboot}/u-boot-dtb.bin -n fallback/payload -c lzma -l 0x1110000 -e 0x1110000
          '';
        };
        coreboot-msi-ms-7d25 = final.buildCoreboot {
          boardName = "msi-ms-7d25";
          configfile = ./coreboot/msi-ms-7d25.config;
          extraConfig =
            let
              vbt = prev.fetchurl {
                url = "https://github.com/intel/FSP/raw/d85493d0605921f46afab3445be01da90f0a8062/AlderLakeFspBinPkg/Client/AlderLakeP/SampleCode/Vbt/Vbt.bin";
                sha256 = "sha256-bmdHLfbNIR1zCt2OMxCCLCPoqJskaUbnBZYQcJoJ/LQ=";
              };
            in
            ''
              CONFIG_INTEL_GMA_VBT_FILE="${vbt}"
              CONFIG_PAYLOAD_FILE="${final.tinyboot-kernel}/bzImage"
              CONFIG_LINUX_INITRD="${final.tinyboot-initramfs}/initrd"
            '';
        };
        coreboot-kukui-fennel14 = final.buildCoreboot {
          boardName = "kukui-fennel14";
          configfile = ./coreboot/kukui-fennel.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-mediatek-fitimage}/uImage"
          '';
        };
        coreboot-asurada-spherion = final.buildCoreboot {
          boardName = "asurada-spherion";
          configfile = ./coreboot/asurada-spherion.config;
          extraConfig = ''
            CONFIG_PAYLOAD_FILE="${final.linuxboot-mediatek-fitimage}/uImage"
          '';
        };

        jmbaur-keybase-pgp-keys = prev.fetchurl {
          url = "https://keybase.io/jaredbaur/pgp_keys.asc";
          sha256 = "sha256-R2a+bF7E6Zogl5XWsjrK5dkCAvK6K2h/bje37aYSgGc=";
        };
        jmbaur-github-ssh-keys = prev.fetchurl {
          url = "https://github.com/jmbaur.keys";
          sha256 = "sha256-AWOgwTfJ7a2t+8VOViNQCXMDGe+zx29jHOqgFPnlzCo=";
        };
      })
  ];
}
